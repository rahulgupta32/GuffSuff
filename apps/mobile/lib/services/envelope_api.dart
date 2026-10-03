import 'dart:convert';
import 'auth_session.dart';

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
