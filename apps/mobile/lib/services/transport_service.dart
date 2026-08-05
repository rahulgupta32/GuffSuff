import 'dart:convert';
import 'dart:math';

enum MessageState { queued, sending, accepted, delivered, read, failed }

class TransportMessage {
  final String id;
  final String conversationId;
  final String senderUserId;
  final String recipientUserId;
  final String opaquePayloadBase64;
  final MessageState state;
  final DateTime createdAt;

  TransportMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.opaquePayloadBase64,
    required this.state,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderUserId': senderUserId,
        'recipientUserId': recipientUserId,
        'opaquePayloadBase64': opaquePayloadBase64,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

class TransportService {
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');

  void checkProductionSafety() {
    if (isProductionBuild) {
      throw UnsupportedError(
        'Transport test mode is strictly prohibited in release/production builds.',
      );
    }
  }

  TransportMessage createOpaqueTestPayload({
    required String conversationId,
    required String senderUserId,
    required String recipientUserId,
  }) {
    checkProductionSafety();

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final opaquePayload = base64Encode(bytes);

    return TransportMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      opaquePayloadBase64: opaquePayload,
      state: MessageState.queued,
      createdAt: DateTime.now(),
    );
  }
}
