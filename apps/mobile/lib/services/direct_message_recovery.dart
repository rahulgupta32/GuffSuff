import '../crypto/android_direct_crypto.dart';
import 'auth_session.dart';
import 'envelope_api.dart';
import 'prekey_api.dart';

/// Reconciles previously committed messages. New-message preparation and the
/// composer remain disabled until durable claim intents are implemented.
class DirectMessageRecoveryCoordinator {
  final AndroidDirectCrypto crypto;
  final EnvelopeApi envelopes;
  final DateTime Function() clock;
  bool _busy = false;
  DirectMessageRecoveryCoordinator(this.crypto, this.envelopes, {
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc()) {
    if (!identical(crypto.session, envelopes.session)) {
      throw ArgumentError('Recovery requires one authenticated session');
    }
  }

  /// Uses saved inventory, routing, timestamps, retry ID and exact ciphertext.
  /// No recipient rediscovery, prekey claim or encryption occurs on this path.
  Future<int> retryPending(String conversationId) => _guarded((check) async {
    final batches = await crypto.pending(publicId(conversationId));
    check();
    var accepted = 0;
    for (final batch in batches) {
      final route = batch.route;
      // Retain expired records for history/recovery; do not silently discard them.
      if (route.expiresAtMillis <= clock().millisecondsSinceEpoch) continue;
      check();
      final envelope = await envelopes.submitDevices(
        conversationId: route.conversationId,
        recipientUserId: route.recipientUserId,
        messageId: batch.messageId,
        ciphertexts: batch.ciphertexts,
        createdAt: DateTime.fromMillisecondsSinceEpoch(route.createdAtMillis, isUtc: true),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(route.expiresAtMillis, isUtc: true),
      );
      check();
      await crypto.accepted(batch, envelope);
      check();
      accepted++;
    }
    return accepted;
  });

  /// Native verification/history commits before HTTP delivery acknowledgement.
  /// Failed acknowledgements remain retryable without advancing the ratchet again.
  Future<List<VerifiedDirectMessage>> receivePending(String conversationId) => _guarded((check) async {
    final pending = await envelopes.pendingDirect(publicId(conversationId), now: clock());
    check();
    final result = <VerifiedDirectMessage>[];
    for (final envelope in pending) {
      final message = await crypto.receive(envelope);
      check();
      await envelopes.delivered(envelope.id);
      check();
      result.add(message);
    }
    return List.unmodifiable(result);
  });

  Future<T> _guarded<T>(Future<T> Function(void Function()) action) async {
    if (_busy) throw StateError('Message recovery is already running');
    final session = crypto.session;
    if (!session.isAuthenticated) throw AuthFailure('Please sign in again.');
    final account = session.userId;
    final device = session.deviceId;
    final family = session.sessionId;
    var changed = false;
    void observe() {
      if (!session.isAuthenticated || session.userId != account ||
          session.deviceId != device || session.sessionId != family) {
        changed = true;
      }
    }
    void check() {
      observe();
      if (changed) throw AuthFailure('The session changed. Please try again.');
    }
    _busy = true;
    session.addListener(observe);
    try {
      check();
      final result = await action(check);
      check();
      return result;
    } finally {
      session.removeListener(observe);
      _busy = false;
    }
  }
}
