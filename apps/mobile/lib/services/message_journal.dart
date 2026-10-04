import 'dart:convert';
import 'envelope_api.dart';
import 'secure_storage.dart';

/// Small, bounded ciphertext journal. It is deliberately not a plaintext
/// chat-history database. One instance must own a given account/device scope.
class MessageJournal {
  final SecureStorageService storage;
  final String scope;
  final String userId, deviceId;
  final int maxBytes;
  Future<void> _tail = Future.value();
  MessageJournal({
    required this.storage,
    required this.userId,
    required this.deviceId,
    this.maxBytes = 256 * 1024,
  }) : scope =
           '${Uri.encodeComponent(userId)}_${Uri.encodeComponent(deviceId)}';

  void _checkOwner(EnvelopeApi api) {
    if (api.session.userId != userId ||
        api.session.deviceId != deviceId ||
        !api.session.isAuthenticated) {
      throw StateError('The journal belongs to a different account or device');
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<Map<String, dynamic>> _load() async {
    final raw = await storage.readMessageJournal(scope);
    if (raw == null) {
      return {'version': 1, 'outbox': <dynamic>[], 'inbox': <dynamic>[]};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['outbox'] is! List ||
        decoded['inbox'] is! List) {
      throw const FormatException(
        'Invalid message journal; recovery is required',
      );
    }
    return decoded;
  }

  Future<void> _save(Map<String, dynamic> state) async {
    final raw = jsonEncode(state);
    if (utf8.encode(raw).length > maxBytes) {
      throw StateError('Message storage is full');
    }
    await storage.writeMessageJournal(scope, raw);
  }

  Future<void> enqueue(Map<String, dynamic> envelope) => _serialized(() async {
    final entry = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(envelope)) as Map,
    );
    final payload = entry['opaquePayloadBase64'];
    if (payload is! String ||
        payload.isEmpty ||
        base64Decode(payload).isEmpty ||
        base64Decode(payload).length > 65536 ||
        base64Encode(base64Decode(payload)) != payload ||
        entry['idempotencyKey'] is! String ||
        (entry['idempotencyKey'] as String).isEmpty ||
        entry.keys.toSet().difference({
          'conversationId',
          'recipientUserId',
          'idempotencyKey',
          'opaquePayloadBase64',
          'protocolVersion',
          'clientCreatedAt',
          'expiresAt',
        }).isNotEmpty) {
      throw ArgumentError('Invalid opaque outgoing envelope');
    }
    for (final field in [
      'conversationId',
      'recipientUserId',
      'clientCreatedAt',
      'expiresAt',
    ]) {
      if (entry[field] is! String) {
        throw ArgumentError('Missing envelope field: $field');
      }
    }
    DateTime.parse(entry['clientCreatedAt'] as String);
    DateTime.parse(entry['expiresAt'] as String);
    final state = await _load();
    final outbox = state['outbox'] as List;
    final existing = outbox.where(
      (e) => e['idempotencyKey'] == entry['idempotencyKey'],
    );
    if (existing.isNotEmpty) {
      if (jsonEncode(existing.first) != jsonEncode(entry)) {
        throw StateError('Retry key already has another envelope');
      }
      return;
    }
    outbox.add(entry);
    await _save(state);
  });

  /// Entries are removed only after server acceptance. If local deletion
  /// fails, the next flush resends the identical persisted retry key.
  Future<void> flush(EnvelopeApi api) => _serialized(() async {
    _checkOwner(api);
    final state = await _load();
    final outbox = state['outbox'] as List;
    while (outbox.isNotEmpty) {
      _checkOwner(api);
      final entry = outbox.first as Map<String, dynamic>;
      await api.submit(
        conversationId: entry['conversationId'],
        recipientUserId: entry['recipientUserId'],
        idempotencyKey: entry['idempotencyKey'],
        ciphertext: base64Decode(entry['opaquePayloadBase64']),
        createdAt: DateTime.parse(entry['clientCreatedAt']),
        expiresAt: DateTime.parse(entry['expiresAt']),
        protocolVersion: entry['protocolVersion'] as int? ?? 1,
      );
      outbox.removeAt(0);
      await _save(state);
    }
  });

  /// Persist first, acknowledge second. Duplicate downloads still acknowledge
  /// so a lost receipt can recover without inserting duplicate local entries.
  Future<int> receive(EnvelopeApi api, String conversationId) =>
      _serialized(() async {
        _checkOwner(api);
        final envelopes = await api.pending(conversationId);
        for (final envelope in envelopes) {
          final id = envelope['id'];
          final payload = envelope['opaque_payload_base64'];
          if (id is! String ||
              envelope['conversation_id'] != conversationId ||
              payload is! String) {
            throw const FormatException('Invalid incoming envelope');
          }
          final normalized = payload.replaceAll(RegExp(r'\s'), '');
          if (normalized.length > 87384) {
            throw const FormatException('Incoming ciphertext is too large');
          }
          final bytes = base64Decode(normalized);
          if (bytes.isEmpty ||
              bytes.length > 65536 ||
              base64Encode(bytes) != normalized) {
            throw const FormatException('Invalid incoming ciphertext');
          }
          final state = await _load();
          final inbox = state['inbox'] as List;
          final existing = inbox.where((e) => e['id'] == id);
          if (existing.isNotEmpty &&
              (existing.first['opaque_payload_base64'] != normalized ||
                  existing.first['conversation_id'] != conversationId)) {
            throw const FormatException(
              'An envelope ID was reused with different ciphertext',
            );
          }
          if (existing.isEmpty) {
            inbox.add({
              'id': id,
              'conversation_id': conversationId,
              'opaque_payload_base64': normalized,
              for (final key in [
                'sender_user_id',
                'sender_device_id',
                'recipient_user_id',
                'protocol_version',
                'client_created_at',
                'server_accepted_at',
                'expires_at',
              ])
                if (envelope.containsKey(key)) key: envelope[key],
            });
            await _save(state);
          }
          _checkOwner(api);
          await api.delivered(id);
        }
        return envelopes.length;
      });

  Future<List<Map<String, dynamic>>> inbox() => _serialized(() async {
    final state = await _load();
    return (state['inbox'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  });
}
