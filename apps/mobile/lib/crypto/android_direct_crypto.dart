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
    final account = publicId(originalAccount);
    final device = publicId(originalDevice);
    if (!session.isAuthenticated) throw AuthFailure('Please sign in again.');
    var changed = false;
    void checkSession() {
      if (!session.isAuthenticated ||
          session.userId != originalAccount ||
          session.deviceId != originalDevice) {
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
    if (claimedBundles.length > 16)
      throw const FormatException('Too many claims');
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
    final response = publicObject(
      await _invoke('sendDirectMessage', {
        'messageId': message,
        'routes': snapshot.map((route) => route.json).toList(),
        'text': text,
        'claimedBundles': claims,
      }),
      {'messageId', 'protocolVersion', 'deviceEnvelopes'},
    );
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
    if (item == null || item is String || item is int || item is bool)
      return item;
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
  if (utf8.encode(text).length > 8192)
    throw const FormatException('Text too large');
}
