import 'dart:async';
import 'dart:convert';
import 'dart:math';

enum MessageState { queued, sending, accepted, delivered, read, failed }

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

class TransportEnvelope {
  final String envelopeId;
  final String conversationId;
  final String senderUserId;
  final String recipientUserId;
  final String opaquePayloadBase64;
  final int sequenceNumber;
  final MessageState state;
  final DateTime createdAt;

  TransportEnvelope({
    required this.envelopeId,
    required this.conversationId,
    required this.senderUserId,
    required this.recipientUserId,
    required this.opaquePayloadBase64,
    required this.sequenceNumber,
    required this.state,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'envelopeId': envelopeId,
    'conversationId': conversationId,
    'senderUserId': senderUserId,
    'recipientUserId': recipientUserId,
    'opaquePayloadBase64': opaquePayloadBase64,
    'sequenceNumber': sequenceNumber,
    'state': state.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TransportService {
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');

  final String wsBaseUrl;
  final String? accessToken;
  final String? deviceId;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  final Set<String> _processedEnvelopeIds = {};
  final Map<String, int> _unreadCounts = {};

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _envelopeController = StreamController<TransportEnvelope>.broadcast();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelayMs = 30000;
  static const int _baseDelayMs = 1000;

  TransportService({required this.wsBaseUrl, this.accessToken, this.deviceId});

  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<TransportEnvelope> get onEnvelopeReceived =>
      _envelopeController.stream;

  void checkProductionSafety() {
    if (isProductionBuild) {
      throw UnsupportedError(
        'Transport test mode is strictly prohibited in release/production builds.',
      );
    }
  }

  void connect() {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }
    _setStatus(ConnectionStatus.connecting);

    // Simulate WebSocket lifecycle connection
    Future.delayed(const Duration(milliseconds: 300), () {
      _setStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _setStatus(ConnectionStatus.disconnected);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_status == ConnectionStatus.connected) {
        // Send heartbeat ping envelope over transport
      }
    });
  }

  void scheduleReconnect() {
    if (_status == ConnectionStatus.reconnecting) return;
    _setStatus(ConnectionStatus.reconnecting);
    _heartbeatTimer?.cancel();

    _reconnectAttempts++;
    final backoff = min(
      _baseDelayMs * pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelayMs,
    );
    final jitter = Random().nextInt(500);
    final delay = backoff + jitter;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect();
    });
  }

  void processIncomingEnvelope(TransportEnvelope envelope) {
    // Envelope De-duplication Check
    if (_processedEnvelopeIds.contains(envelope.envelopeId)) {
      return; // Duplicate envelope ignored safely
    }
    _processedEnvelopeIds.add(envelope.envelopeId);

    // Track unread counter per conversation
    final currentUnread = _unreadCounts[envelope.conversationId] ?? 0;
    _unreadCounts[envelope.conversationId] = currentUnread + 1;

    _envelopeController.add(envelope);
  }

  int getUnreadCount(String conversationId) =>
      _unreadCounts[conversationId] ?? 0;

  void markConversationRead(String conversationId) {
    _unreadCounts[conversationId] = 0;
  }

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  TransportEnvelope createOpaqueTestPayload({
    required String conversationId,
    required String senderUserId,
    required String recipientUserId,
  }) {
    checkProductionSafety();

    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final opaquePayload = base64Encode(bytes);

    return TransportEnvelope(
      envelopeId: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderUserId: senderUserId,
      recipientUserId: recipientUserId,
      opaquePayloadBase64: opaquePayload,
      sequenceNumber: 1,
      state: MessageState.queued,
      createdAt: DateTime.now(),
    );
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _envelopeController.close();
  }
}
