import '../crypto/android_direct_crypto.dart';
import 'auth_session.dart';
import 'envelope_api.dart';
import 'prekey_api.dart';

/// Coordinates protected preparation, encryption and committed-message recovery.
/// Application/provider wiring and the composer remain disabled.
class DirectMessageRecoveryCoordinator {
  final AndroidDirectCrypto crypto;
  final EnvelopeApi envelopes;
  final PrekeyApi? prekeys;
  final DateTime Function() clock;
  bool _busy = false;
  DirectMessageRecoveryCoordinator(
    this.crypto,
    this.envelopes, {
    this.prekeys,
    DateTime Function()? clock,
  }) : clock = clock ?? (() => DateTime.now().toUtc()) {
    if (!identical(crypto.session, envelopes.session) ||
        (prekeys != null && !identical(crypto.session, prekeys!.session))) {
      throw ArgumentError('Recovery requires one authenticated session');
    }
  }

  PrekeyApi _prekeys() => prekeys ??
      (throw StateError('Prekey transport is required for prepared sends'));

  /// Discovery precedes preparation; no prekey claims are made until native
  /// storage commits the immutable inventory, timestamps, text and retry IDs.
  Future<PreparedDirectIntent> prepareNew({
    required String messageId,
    required String conversationId,
    required String recipientUserId,
    required String text,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) => _guarded((check) async {
    final api = _prekeys();
    final message = publicId(messageId);
    final conversation = publicId(conversationId);
    final recipient = publicId(recipientUserId);
    if (createdAt.microsecondsSinceEpoch % 1000 != 0 ||
        expiresAt.microsecondsSinceEpoch % 1000 != 0 ||
        !expiresAt.isAfter(createdAt) || !expiresAt.isAfter(clock())) {
      throw const FormatException('Invalid prepared timestamps');
    }
    final account = publicId(crypto.session.userId);
    final device = publicId(crypto.session.deviceId);
    final inventory = await api.recipientDevices(conversation, recipient);
    check();
    final routes = inventory.map((target) => DirectCryptoRoute(
      conversationId: conversation, senderUserId: account, senderDeviceId: device,
      recipientUserId: recipient, recipientDeviceId: target,
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      expiresAtMillis: expiresAt.millisecondsSinceEpoch,
    )).toList();
    final prepared = await crypto.prepare(messageId: message, routes: routes, text: text);
    check();
    return prepared;
  });

  /// Restores drafts and their original claim UUIDs. Lost claim/completion
  /// responses remain recoverable from native drafts or committed ciphertext.
  Future<int> resumePrepared(String conversationId) => _guarded((check) async {
    final api = _prekeys();
    final conversation = publicId(conversationId);
    final drafts = await crypto.prepared(conversation);
    check();
    for (final draft in drafts) {
      if (draft.routes.first.expiresAtMillis <= clock().millisecondsSinceEpoch) {
        continue;
      }
      final claims = <PublicPrekeyBundle>[];
      for (final target in draft.requiredClaimDeviceIds) {
        check();
        if (draft.routes.first.expiresAtMillis <= clock().millisecondsSinceEpoch) {
          throw const FormatException('Prepared message expired during claims');
        }
        claims.add(await api.claim(conversationId: conversation, deviceId: target,
            claimId: draft.claimIds[target]!));
        check();
      }
      check();
      if (draft.routes.first.expiresAtMillis <= clock().millisecondsSinceEpoch) {
        throw const FormatException('Prepared message expired before encryption');
      }
      await crypto.complete(draft, claims);
      check();
    }
    return _retryPending(conversation, check);
  });

  /// Uses saved inventory, routing, timestamps, retry ID and exact ciphertext.
  /// No recipient rediscovery, prekey claim or encryption occurs on this path.
  Future<int> retryPending(String conversationId) =>
      _guarded((check) => _retryPending(publicId(conversationId), check));

  Future<int> _retryPending(String conversationId, void Function() check) async {
    final batches = await crypto.pending(conversationId);
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
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          route.createdAtMillis,
          isUtc: true,
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          route.expiresAtMillis,
          isUtc: true,
        ),
      );
      check();
      await crypto.accepted(batch, envelope);
      check();
      accepted++;
    }
    return accepted;
  }

  /// Native verification/history commits before HTTP delivery acknowledgement.
  /// Failed acknowledgements remain retryable without advancing the ratchet again.
  Future<List<VerifiedDirectMessage>> receivePending(String conversationId) =>
      _guarded((check) async {
        final pending = await envelopes.pendingDirect(
          publicId(conversationId),
          now: clock(),
        );
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
      if (!session.isAuthenticated ||
          session.userId != account ||
          session.deviceId != device ||
          session.sessionId != family) {
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
