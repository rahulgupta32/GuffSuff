import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/auth_session.dart';
import '../services/envelope_api.dart';
import '../services/prekey_api.dart';

/// Public codec adapter to protected Android transactions. This adapter does
/// not enable the composer or perform HTTP, claims, acknowledgements or retries.
class AndroidDirectCrypto {
  final AuthSession session;
  final MethodChannel channel;
  final DateTime Function() clock;
  AndroidDirectCrypto(
    this.session, {
    this.channel = const MethodChannel('guffsuff/native_identity'),
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc());

  Future<Map<String, dynamic>> _invoke(
    String method,
    Map<String, dynamic> args,
  ) async {
    final originalAccount = session.userId;
    final originalDevice = session.deviceId;
    final originalSession = session.sessionId;
    final account = publicId(originalAccount);
    final device = publicId(originalDevice);
    if (!session.isAuthenticated) throw AuthFailure('Please sign in again.');
    var changed = false;
    void checkSession() {
      if (!session.isAuthenticated ||
          session.userId != originalAccount ||
          session.deviceId != originalDevice ||
          session.sessionId != originalSession) {
        changed = true;
      }
    }

    session.addListener(checkSession);
    try {
      final response = await channel.invokeMethod<dynamic>(method, {
        'accountId': account,
        'deviceId': device,
        ...args,
      });
      checkSession();
      if (changed) throw AuthFailure('The session changed. Please try again.');
      return _codecObject(response);
    } on PlatformException {
      throw const CryptoBridgeFailure();
    } on MissingPluginException {
      throw const CryptoBridgeFailure();
    } finally {
      session.removeListener(checkSession);
    }
  }

  Future<PublicPrekeyBundle> initializePreKeys() async {
    final result = await _invoke('initializePreKeys', {});
    publicObject(result, {
      'providerId',
      'providerVersion',
      'identityPublicKeyBase64',
      'registrationId',
      'supportsDirectMessaging',
      'bundle',
    });
    if (result['providerId'] != 'signalapp/libsignal' ||
        result['providerVersion'] != '0.104.0' ||
        result['supportsDirectMessaging'] != false) {
      throw const FormatException('Unsupported native provider');
    }
    final bundle = PublicPrekeyBundle.parse(result['bundle'], now: clock());
    if (result['identityPublicKeyBase64'] !=
            bundle.json['identityPublicKeyBase64'] ||
        result['registrationId'] != bundle.json['registrationId']) {
      throw const FormatException('Native identity mismatch');
    }
    return bundle;
  }

  /// Claims must already be authorized and their retry IDs durably persisted.
  /// Native code verifies signatures, pins, routes and commits ciphertext first.
  Future<Map<String, List<int>>> send({
    required String messageId,
    required List<DirectCryptoRoute> routes,
    required String text,
    required List<PublicPrekeyBundle> claimedBundles,
  }) async {
    final message = publicId(messageId);
    final account = publicId(session.userId);
    final device = publicId(session.deviceId);
    _text(text);
    final snapshot = List<DirectCryptoRoute>.from(routes);
    final ids = snapshot.map((route) => route.recipientDeviceId).toSet();
    if (snapshot.isEmpty ||
        snapshot.length > 16 ||
        ids.length != snapshot.length ||
        snapshot.any(
          (route) =>
              route.senderUserId != account || route.senderDeviceId != device,
        )) {
      throw const FormatException('Invalid outgoing routes');
    }
    final first = snapshot.first;
    if (snapshot.any(
      (route) =>
          route.conversationId != first.conversationId ||
          route.recipientUserId != first.recipientUserId ||
          route.createdAtMillis != first.createdAtMillis ||
          route.expiresAtMillis != first.expiresAtMillis,
    )) {
      throw const FormatException('Inconsistent outgoing routes');
    }
    if (claimedBundles.length > 16) {
      throw const FormatException('Too many claims');
    }
    final claims = <Map<String, dynamic>>[];
    final claimIds = <String>{};
    for (final claim in claimedBundles) {
      final id = publicId(claim.json['deviceId']);
      if (!ids.contains(id) || !claimIds.add(id)) {
        throw const FormatException('Claim target mismatch');
      }
      claims.add(
        PublicPrekeyBundle.parse(
          claim.json,
          now: clock(),
          expectedDeviceId: id,
        ).json,
      );
    }
    final response = await _invoke('sendDirectMessage', {
      'messageId': message,
      'routes': snapshot.map((route) => route.json).toList(),
      'text': text,
      'claimedBundles': claims,
    });
    return _batch(response, message, ids);
  }

  Map<String, List<int>> _batch(
    dynamic value,
    String message,
    Set<String> ids,
  ) {
    final response = publicObject(value, {
      'messageId',
      'protocolVersion',
      'deviceEnvelopes',
    });
    if (response['messageId'] != message ||
        response['protocolVersion'] is! int ||
        response['protocolVersion'] != 2) {
      throw const FormatException('Native batch mismatch');
    }
    final entries = response['deviceEnvelopes'];
    if (entries is! List || entries.length != ids.length) {
      throw const FormatException('Native device inventory mismatch');
    }
    final batch = <String, List<int>>{};
    var total = 0;
    for (final entry in entries) {
      final data = publicObject(entry, {
        'recipientDeviceId',
        'opaquePayloadBase64',
      });
      final id = publicId(data['recipientDeviceId']);
      if (!ids.contains(id) || batch.containsKey(id)) {
        throw const FormatException('Native device mismatch');
      }
      publicBytes(data['opaquePayloadBase64'], 13, 65536);
      final bytes = base64Decode(data['opaquePayloadBase64'] as String);
      total += bytes.length;
      batch[id] = List<int>.unmodifiable(bytes);
    }
    if (total > 65536) throw const FormatException('Native batch too large');
    return Map<String, List<int>>.unmodifiable(batch);
  }

  /// Native storage commits the complete intent and stable claim IDs before
  /// this method returns. The caller must not issue HTTP claims earlier.
  Future<PreparedDirectIntent> prepare({
    required String messageId,
    required List<DirectCryptoRoute> routes,
    required String text,
  }) async {
    final message = publicId(messageId);
    _text(text);
    final snapshot = List<DirectCryptoRoute>.from(routes)
      ..sort((a, b) => a.recipientDeviceId.compareTo(b.recipientDeviceId));
    _outgoingRoutes(snapshot);
    if (snapshot.first.expiresAtMillis <= clock().millisecondsSinceEpoch) {
      throw const FormatException('Message expired');
    }
    final result = _prepared(
      await _invoke('prepareDirectMessage', {
        'messageId': message,
        'routes': snapshot.map((route) => route.json).toList(),
        'text': text,
      }),
    );
    if (result.messageId != message ||
        result.text != text ||
        jsonEncode(result.routes.map((route) => route.json).toList()) !=
            jsonEncode(snapshot.map((route) => route.json).toList())) {
      throw const FormatException('Prepared intent mismatch');
    }
    return result;
  }

  /// Restores original drafts, including expired drafts retained for recovery.
  Future<List<PreparedDirectIntent>> prepared(String conversationId) async {
    final conversation = publicId(conversationId);
    final response = publicObject(
      await _invoke('preparedDirectMessages', {'conversationId': conversation}),
      {'prepared'},
    );
    final rows = response['prepared'];
    if (rows is! List || rows.length > 64) {
      throw const FormatException('Invalid prepared list');
    }
    final ids = <String>{};
    final result = <PreparedDirectIntent>[];
    for (final row in rows) {
      final intent = _prepared(row);
      if (!ids.add(intent.messageId) ||
          intent.routes.first.conversationId != conversation) {
        throw const FormatException('Prepared conversation mismatch');
      }
      result.add(intent);
    }
    return List.unmodifiable(result);
  }

  /// Uses the stored native intent; failed completion retains it atomically.
  Future<Map<String, List<int>>> complete(
    PreparedDirectIntent intent,
    List<PublicPrekeyBundle> claimedBundles,
  ) async {
    _outgoingRoutes(intent.routes);
    final ids = intent.routes.map((route) => route.recipientDeviceId).toSet();
    if (claimedBundles.length > 16) {
      throw const FormatException('Too many claims');
    }
    final targets = <String>{};
    final claims = <Map<String, dynamic>>[];
    for (final claim in claimedBundles) {
      final target = publicId(claim.json['deviceId']);
      if (!ids.contains(target) || !targets.add(target)) {
        throw const FormatException('Claim target mismatch');
      }
      claims.add(
        PublicPrekeyBundle.parse(
          claim.json,
          now: clock(),
          expectedDeviceId: target,
        ).json,
      );
    }
    return _batch(
      await _invoke('completePreparedMessage', {
        'messageId': intent.messageId,
        'claimedBundles': claims,
      }),
      intent.messageId,
      ids,
    );
  }

  void _outgoingRoutes(List<DirectCryptoRoute> routes) {
    final account = publicId(session.userId);
    final device = publicId(session.deviceId);
    if (routes.isEmpty ||
        routes.length > 16 ||
        routes.map((route) => route.recipientDeviceId).toSet().length !=
            routes.length) {
      throw const FormatException('Invalid prepared inventory');
    }
    final first = routes.first;
    if (routes.any(
      (route) =>
          route.senderUserId != account ||
          route.senderDeviceId != device ||
          route.conversationId != first.conversationId ||
          route.recipientUserId != first.recipientUserId ||
          route.createdAtMillis != first.createdAtMillis ||
          route.expiresAtMillis != first.expiresAtMillis,
    )) {
      throw const FormatException('Prepared routing mismatch');
    }
  }

  PreparedDirectIntent _prepared(dynamic value) {
    final row = publicObject(value, {
      'messageId',
      'routes',
      'text',
      'claimIds',
      'requiredClaimDeviceIds',
    });
    final message = publicId(row['messageId']);
    final entries = row['routes'];
    if (entries is! List || entries.isEmpty || entries.length > 16) {
      throw const FormatException('Invalid prepared routes');
    }
    final routes = entries.map(DirectCryptoRoute.parse).toList();
    _outgoingRoutes(routes);
    final targets = routes.map((route) => route.recipientDeviceId).toList();
    final sorted = List<String>.from(targets)..sort();
    if (jsonEncode(targets) != jsonEncode(sorted)) {
      throw const FormatException('Unsorted prepared routes');
    }
    final text = row['text'];
    if (text is! String) throw const FormatException('Invalid prepared text');
    _text(text);
    final rawClaims = row['claimIds'];
    if (rawClaims is! Map<String, dynamic> ||
        rawClaims.length != targets.length ||
        !rawClaims.keys.every(targets.contains)) {
      throw const FormatException('Invalid prepared claim inventory');
    }
    final claims = rawClaims.map(
      (target, claim) => MapEntry(target, publicId(claim)),
    );
    if (claims.values.toSet().length != claims.length) {
      throw const FormatException('Duplicate prepared claims');
    }
    final required = row['requiredClaimDeviceIds'];
    if (required is! List || required.length > targets.length) {
      throw const FormatException('Invalid required claim inventory');
    }
    final requiredIds = required.map(publicId).toList();
    if (requiredIds.toSet().length != requiredIds.length ||
        !requiredIds.every(targets.contains)) {
      throw const FormatException('Required claim target mismatch');
    }
    return PreparedDirectIntent._(
      message,
      List.unmodifiable(routes),
      text,
      Map.unmodifiable(claims),
      List.unmodifiable(requiredIds),
    );
  }

  /// Only verified text is returned after the native history transaction commits.
  /// The coordinator must check its session again before any delivery receipt.
  Future<VerifiedDirectMessage> receive(DirectEnvelope envelope) async {
    final route = DirectCryptoRoute.fromEnvelope(envelope);
    if (route.recipientUserId != publicId(session.userId) ||
        route.recipientDeviceId != publicId(session.deviceId)) {
      throw const FormatException('Incoming scope mismatch');
    }
    final encoded = base64Encode(envelope.ciphertext);
    publicBytes(encoded, 13, 65536);
    final response = publicObject(
      await _invoke('receiveDirectMessage', {
        'envelopeId': publicId(envelope.id),
        'route': route.json,
        'opaquePayloadBase64': encoded,
      }),
      {'messageId', 'route', 'text'},
    );
    final verified = DirectCryptoRoute.parse(response['route']);
    if (jsonEncode(verified.json) != jsonEncode(route.json)) {
      throw const FormatException('Verified route mismatch');
    }
    final text = response['text'];
    if (text is! String) throw const FormatException('Invalid verified text');
    _text(text);
    return VerifiedDirectMessage(
      publicId(response['messageId']),
      verified,
      text,
    );
  }

  /// Restores ciphertext already committed by native encryption, including expired
  /// entries. Expired entries must not be submitted as new network messages.
  Future<List<RecoveredDirectBatch>> pending(String conversationId) async {
    final conversation = publicId(conversationId);
    final account = publicId(session.userId);
    final device = publicId(session.deviceId);
    final response = publicObject(
      await _invoke('pendingDirectMessages', {'conversationId': conversation}),
      {'pending'},
    );
    final rows = response['pending'];
    if (rows is! List || rows.length > 64) {
      throw const FormatException('Invalid saved batch list');
    }
    final ids = <String>{};
    final result = <RecoveredDirectBatch>[];
    for (final value in rows) {
      final row = publicObject(value, {
        'messageId',
        'route',
        'batchFingerprintBase64',
        'deviceEnvelopes',
      });
      final message = publicId(row['messageId']);
      final route = DirectCryptoRoute.parse(row['route']);
      if (!ids.add(message) ||
          route.conversationId != conversation ||
          route.senderUserId != account ||
          route.senderDeviceId != device) {
        throw const FormatException('Saved batch scope mismatch');
      }
      publicBytes(row['batchFingerprintBase64'], 32, 32);
      final entries = row['deviceEnvelopes'];
      if (entries is! List || entries.isEmpty || entries.length > 16) {
        throw const FormatException('Invalid saved device inventory');
      }
      final batch = <String, List<int>>{};
      var total = 0;
      for (final entry in entries) {
        final data = publicObject(entry, {
          'recipientDeviceId',
          'opaquePayloadBase64',
        });
        final id = publicId(data['recipientDeviceId']);
        if (id == device || batch.containsKey(id)) {
          throw const FormatException('Invalid saved device target');
        }
        publicBytes(data['opaquePayloadBase64'], 13, 65536);
        final bytes = base64Decode(data['opaquePayloadBase64'] as String);
        total += bytes.length;
        batch[id] = List<int>.unmodifiable(bytes);
      }
      final targets = batch.keys.toList()..sort();
      if (total > 65536 || route.recipientDeviceId != targets.first) {
        throw const FormatException('Saved batch inventory mismatch');
      }
      result.add(
        RecoveredDirectBatch._(
          message,
          route,
          row['batchFingerprintBase64'] as String,
          Map.unmodifiable(batch),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  /// Call only after authenticated acceptance of this exact restored batch.
  Future<void> accepted(
    RecoveredDirectBatch batch,
    String serverEnvelopeId,
  ) async {
    if (batch.route.senderUserId != publicId(session.userId) ||
        batch.route.senderDeviceId != publicId(session.deviceId)) {
      throw const FormatException('Acceptance scope mismatch');
    }
    final envelope = publicId(serverEnvelopeId);
    final response = publicObject(
      await _invoke('markDirectMessageAccepted', {
        'messageId': batch.messageId,
        'serverEnvelopeId': envelope,
        'batchFingerprintBase64': batch.fingerprintBase64,
      }),
      {'messageId', 'serverEnvelopeId', 'isAccepted'},
    );
    if (response['messageId'] != batch.messageId ||
        response['serverEnvelopeId'] != envelope ||
        response['isAccepted'] != true) {
      throw const FormatException('Native acceptance mismatch');
    }
  }

  Future<List<DirectHistoryEntry>> history(String conversationId) async {
    final conversation = publicId(conversationId);
    final account = publicId(session.userId);
    final device = publicId(session.deviceId);
    final response = publicObject(
      await _invoke('directMessageHistory', {'conversationId': conversation}),
      {'history'},
    );
    final rows = response['history'];
    if (rows is! List || rows.length > 192) {
      throw const FormatException('Invalid saved history list');
    }
    final ids = <String>{};
    final result = <DirectHistoryEntry>[];
    for (final value in rows) {
      final row = publicObject(value, {
        'recordId',
        'direction',
        'messageId',
        'route',
        'text',
        'isAccepted',
        'serverEnvelopeId',
      });
      final record = publicId(row['recordId']);
      final message = publicId(row['messageId']);
      final direction = row['direction'];
      final accepted = row['isAccepted'];
      final envelope =
          row['serverEnvelopeId'] == null
              ? null
              : publicId(row['serverEnvelopeId']);
      final route = DirectCryptoRoute.parse(row['route']);
      if (!['incoming', 'outgoing'].contains(direction) ||
          accepted is! bool ||
          !ids.add('$direction/$record') ||
          route.conversationId != conversation) {
        throw const FormatException('Invalid saved history record');
      }
      if (direction == 'outgoing') {
        if (record != message ||
            route.senderUserId != account ||
            route.senderDeviceId != device ||
            (!accepted && envelope != null)) {
          throw const FormatException('Outgoing history mismatch');
        }
      } else if (route.recipientUserId != account ||
          route.recipientDeviceId != device ||
          !accepted ||
          envelope != record) {
        throw const FormatException('Incoming history mismatch');
      }
      final text = row['text'];
      if (text is! String) throw const FormatException('Invalid saved text');
      _text(text);
      result.add(
        DirectHistoryEntry(
          record,
          direction as String,
          VerifiedDirectMessage(message, route, text),
          accepted,
          envelope,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}

class PreparedDirectIntent {
  final String messageId, text;
  final List<DirectCryptoRoute> routes;
  final Map<String, String> claimIds;
  final List<String> requiredClaimDeviceIds;
  PreparedDirectIntent._(
    this.messageId,
    this.routes,
    this.text,
    this.claimIds,
    this.requiredClaimDeviceIds,
  );
}

class RecoveredDirectBatch {
  final String messageId, fingerprintBase64;
  final DirectCryptoRoute route;
  final Map<String, List<int>> ciphertexts;
  RecoveredDirectBatch._(
    this.messageId,
    this.route,
    this.fingerprintBase64,
    this.ciphertexts,
  );
}

class DirectHistoryEntry {
  final String recordId, direction;
  final VerifiedDirectMessage message;
  final bool isAccepted;
  final String? serverEnvelopeId;
  const DirectHistoryEntry(
    this.recordId,
    this.direction,
    this.message,
    this.isAccepted,
    this.serverEnvelopeId,
  );
}

class CryptoBridgeFailure implements Exception {
  const CryptoBridgeFailure();
  @override
  String toString() =>
      'Secure messaging unavailable; recovery may be required.';
}

class VerifiedDirectMessage {
  final String messageId, text;
  final DirectCryptoRoute route;
  const VerifiedDirectMessage(this.messageId, this.route, this.text);
}

class DirectCryptoRoute {
  final String conversationId,
      senderUserId,
      senderDeviceId,
      recipientUserId,
      recipientDeviceId;
  final int createdAtMillis, expiresAtMillis;
  DirectCryptoRoute({
    required String conversationId,
    required String senderUserId,
    required String senderDeviceId,
    required String recipientUserId,
    required String recipientDeviceId,
    required this.createdAtMillis,
    required this.expiresAtMillis,
  }) : conversationId = publicId(conversationId),
       senderUserId = publicId(senderUserId),
       senderDeviceId = publicId(senderDeviceId),
       recipientUserId = publicId(recipientUserId),
       recipientDeviceId = publicId(recipientDeviceId) {
    publicInteger(createdAtMillis, 1, 8640000000000000);
    publicInteger(expiresAtMillis, 1, 8640000000000000);
    if (expiresAtMillis <= createdAtMillis ||
        this.senderUserId == this.recipientUserId ||
        this.senderDeviceId == this.recipientDeviceId) {
      throw const FormatException('Invalid crypto route');
    }
  }
  factory DirectCryptoRoute.fromEnvelope(DirectEnvelope envelope) {
    if (envelope.createdAt.microsecondsSinceEpoch % 1000 != 0 ||
        envelope.expiresAt.microsecondsSinceEpoch % 1000 != 0) {
      throw const FormatException('Millisecond routing required');
    }
    return DirectCryptoRoute(
      conversationId: envelope.conversationId,
      senderUserId: envelope.senderUserId,
      senderDeviceId: envelope.senderDeviceId,
      recipientUserId: envelope.recipientUserId,
      recipientDeviceId: envelope.recipientDeviceId,
      createdAtMillis: envelope.createdAt.millisecondsSinceEpoch,
      expiresAtMillis: envelope.expiresAt.millisecondsSinceEpoch,
    );
  }
  factory DirectCryptoRoute.parse(dynamic value) {
    final data = publicObject(value, {
      'conversationId',
      'senderUserId',
      'senderDeviceId',
      'recipientUserId',
      'recipientDeviceId',
      'createdAtMillis',
      'expiresAtMillis',
      'protocolVersion',
    });
    publicInteger(data['protocolVersion'], 2, 2);
    return DirectCryptoRoute(
      conversationId: publicId(data['conversationId']),
      senderUserId: publicId(data['senderUserId']),
      senderDeviceId: publicId(data['senderDeviceId']),
      recipientUserId: publicId(data['recipientUserId']),
      recipientDeviceId: publicId(data['recipientDeviceId']),
      createdAtMillis: publicInteger(
        data['createdAtMillis'],
        1,
        8640000000000000,
      ),
      expiresAtMillis: publicInteger(
        data['expiresAtMillis'],
        1,
        8640000000000000,
      ),
    );
  }
  Map<String, dynamic> get json => Map<String, dynamic>.unmodifiable({
    'conversationId': conversationId,
    'senderUserId': senderUserId,
    'senderDeviceId': senderDeviceId,
    'recipientUserId': recipientUserId,
    'recipientDeviceId': recipientDeviceId,
    'createdAtMillis': createdAtMillis,
    'expiresAtMillis': expiresAtMillis,
    'protocolVersion': 2,
  });
}

// StandardMethodCodec returns Map<Object?, Object?> rather than JSON maps.
Map<String, dynamic> _codecObject(dynamic value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid native object');
  }
  dynamic convert(dynamic item) {
    if (item is Map) return _codecObject(item);
    if (item is List) return item.map(convert).toList(growable: false);
    if (item == null || item is String || item is int || item is bool) {
      return item;
    }
    throw const FormatException('Invalid native value');
  }

  return value.map((key, item) => MapEntry(key as String, convert(item)));
}

void _text(String text) {
  if (text.trim().isEmpty || text.length > 8192) {
    throw const FormatException('Invalid message text');
  }
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (++i >= units.length || units[i] < 0xdc00 || units[i] > 0xdfff) {
        throw const FormatException('Invalid Unicode text');
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      throw const FormatException('Invalid Unicode text');
    }
  }
  if (utf8.encode(text).length > 8192) {
    throw const FormatException('Text too large');
  }
}
