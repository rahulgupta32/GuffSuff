import 'dart:convert';
import 'auth_session.dart';
import 'prekey_api.dart';

/// Transports opaque ciphertext. Encryption and durable retry storage belong
/// to the messaging coordinator; this class never accepts message text.
class EnvelopeApi {
  final AuthSession session;
  EnvelopeApi(this.session);

  String _id(String value) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value)) {
      throw ArgumentError('Invalid identifier');
    }
    return value;
  }

  Future<Map<String, dynamic>> createConversation(
    String recipientUserId,
  ) async => _object(
    await session.postJson('conversations/direct', {
      'recipientUserId': _id(recipientUserId),
    }),
  );

  Future<Map<String, dynamic>> submit({
    required String conversationId,
    required String recipientUserId,
    required String idempotencyKey,
    required List<int> ciphertext,
    required DateTime createdAt,
    required DateTime expiresAt,
    int protocolVersion = 1,
  }) async {
    if (ciphertext.isEmpty ||
        ciphertext.length > 65536 ||
        ciphertext.any((b) => b < 0 || b > 255)) {
      throw ArgumentError('Ciphertext must contain 1 to 65536 bytes');
    }
    if (idempotencyKey.isEmpty ||
        idempotencyKey.length > 64 ||
        protocolVersion < 1) {
      throw ArgumentError('Invalid retry key or protocol version');
    }
    return _object(
      await session.postJson('conversations/${_id(conversationId)}/envelopes', {
        'recipientUserId': _id(recipientUserId),
        'idempotencyKey': idempotencyKey,
        'protocolVersion': protocolVersion,
        'opaquePayloadBase64': base64Encode(ciphertext),
        'clientCreatedAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
      }),
    );
  }

  /// The native transaction must persist this exact batch before submission.
  Future<String> submitDevices({
    required String conversationId,
    required String recipientUserId,
    required String messageId,
    required Map<String, List<int>> ciphertexts,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) async {
    final conversation = publicId(conversationId);
    final recipient = publicId(recipientUserId);
    final sender = publicId(session.userId);
    final device = publicId(session.deviceId);
    if (recipient == sender ||
        ciphertexts.isEmpty ||
        ciphertexts.length > 16 ||
        !expiresAt.isAfter(createdAt) ||
        createdAt.microsecondsSinceEpoch % 1000 != 0 ||
        expiresAt.microsecondsSinceEpoch % 1000 != 0) {
      throw const FormatException('Invalid device batch');
    }
    final targets = <String, String>{};
    var total = 0;
    for (final entry in ciphertexts.entries) {
      final id = publicId(entry.key);
      final bytes = List<int>.from(entry.value);
      if (id == device ||
          targets.containsKey(id) ||
          bytes.isEmpty ||
          bytes.length > 65536 ||
          bytes.any((b) => b < 0 || b > 255)) {
        throw const FormatException('Invalid device ciphertext');
      }
      total += bytes.length;
      targets[id] = base64Encode(bytes);
    }
    if (total > 65536)
      throw const FormatException('Ciphertext batch too large');
    final ids = targets.keys.toList()..sort();
    final response = await session.postJson(
      'conversations/$conversation/device-envelopes',
      {
        'conversationId': conversation,
        'recipientUserId': recipient,
        'idempotencyKey': publicId(messageId),
        'protocolVersion': 2,
        'clientCreatedAt': createdAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'deviceEnvelopes':
            ids
                .map(
                  (id) => {
                    'recipientDeviceId': id,
                    'opaquePayloadBase64': targets[id],
                  },
                )
                .toList(),
      },
    );
    final result = _object(response);
    if (publicId(result['conversation_id']) != conversation ||
        publicId(result['sender_user_id']) != sender ||
        publicId(result['sender_device_id']) != device ||
        publicId(result['recipient_user_id']) != recipient ||
        publicInteger(result['protocol_version'], 2, 2) != 2 ||
        result['payload_mode'] != 'per_device' ||
        publicInteger(result['payload_byte_length'], 1, 65536) != total ||
        publicInteger(result['recipientDeviceCount'], 1, 16) !=
            targets.length ||
        result['idempotentRetry'] is! bool ||
        publicExpiry(result['expires_at']).millisecondsSinceEpoch !=
            expiresAt.millisecondsSinceEpoch) {
      throw const FormatException('Device submission response mismatch');
    }
    return publicId(result['id']);
  }

  /// No acknowledgement occurs here: native decryption/history must commit first.
  Future<List<DirectEnvelope>> pendingDirect(
    String conversationId, {
    DateTime? now,
  }) async {
    final conversation = publicId(conversationId);
    final user = publicId(session.userId);
    final device = publicId(session.deviceId);
    final response = await session.getJson(
      'conversations/$conversation/envelopes/pending',
    );
    if (response is! List || response.length > 100) {
      throw const FormatException('Invalid direct envelope list');
    }
    final ids = <String>{};
    final result =
        response.map((value) {
          final data = _object(value);
          final id = publicId(data['id']);
          if (!ids.add(id) ||
              publicId(data['conversation_id']) != conversation ||
              publicId(data['recipient_user_id']) != user ||
              publicId(data['sender_user_id']) == user ||
              publicId(data['sender_device_id']) == device ||
              publicInteger(data['protocol_version'], 2, 2) != 2 ||
              ![
                'accepted',
                'queued',
                'routed',
              ].contains(data['delivery_status'])) {
            throw const FormatException('Direct envelope routing mismatch');
          }
          final created = publicExpiry(data['client_created_at']);
          final expires = publicExpiry(data['expires_at']);
          if (!expires.isAfter(created) ||
              !expires.isAfter(now ?? DateTime.now().toUtc())) {
            throw const FormatException('Invalid direct envelope expiry');
          }
          final encoded = data['opaque_payload_base64'];
          if (encoded is! String || encoded.length > 90000) {
            throw const FormatException('Invalid ciphertext encoding');
          }
          // PostgreSQL encode(bytea, 'base64') inserts LF every 76 characters.
          final normalized = encoded.replaceAll('\n', '');
          publicBytes(normalized, 1, 65536);
          final bytes = base64Decode(normalized);
          if (publicInteger(data['payload_byte_length'], 1, 65536) !=
              bytes.length) {
            throw const FormatException('Ciphertext length mismatch');
          }
          return DirectEnvelope(
            id,
            conversation,
            publicId(data['sender_user_id']),
            publicId(data['sender_device_id']),
            user,
            device,
            created,
            expires,
            bytes,
          );
        }).toList();
    return List.unmodifiable(result);
  }

  Future<List<Map<String, dynamic>>> pending(String conversationId) async {
    final response = await session.getJson(
      'conversations/${_id(conversationId)}/envelopes/pending',
    );
    if (response is! List) {
      throw const FormatException('Invalid pending envelope response');
    }
    return response.map(_object).toList();
  }

  /// Call only after durable local storage succeeds, so a crash cannot lose
  /// ciphertext that the server has already removed from the pending queue.
  Future<void> delivered(String envelopeId) async {
    await session.postJson('envelopes/${_id(envelopeId)}/delivered', {});
  }

  /// Call after the message has actually been displayed to the recipient.
  Future<void> read(String envelopeId) async {
    await session.postJson('envelopes/${_id(envelopeId)}/read', {
      'lastReadEnvelopeId': envelopeId,
    });
  }

  Future<Map<String, dynamic>> status(String envelopeId) async =>
      _object(await session.getJson('envelopes/${_id(envelopeId)}/status'));

  Map<String, dynamic> _object(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid envelope response');
    }
    return value;
  }
}

/// Parsed transport metadata is still untrusted until verified inside native decryption.
class DirectEnvelope {
  final String id,
      conversationId,
      senderUserId,
      senderDeviceId,
      recipientUserId,
      recipientDeviceId;
  final DateTime createdAt, expiresAt;
  final List<int> ciphertext;
  DirectEnvelope(
    this.id,
    this.conversationId,
    this.senderUserId,
    this.senderDeviceId,
    this.recipientUserId,
    this.recipientDeviceId,
    this.createdAt,
    this.expiresAt,
    List<int> bytes,
  ) : ciphertext = List.unmodifiable(bytes);
}
