import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'auth_session.dart';
import 'envelope_api.dart';
import 'message_journal.dart';

enum SyncState { stopped, syncing, ready, retrying }

/// Foreground synchronization only. Push/background execution is separate.
class MessageSync extends ChangeNotifier {
  final EnvelopeApi api;
  final MessageJournal Function(String userId, String deviceId) journalFactory;
  final Duration pollInterval;
  final Map<String, MessageJournal> _journals = {};
  Timer? _timer;
  Future<void>? _inFlight;
  bool _foreground = false, _disposed = false;
  int _failures = 0, _generation = 0;
  String? _owner;
  SyncState state = SyncState.stopped;
  Object? lastError;
  MessageSync({
    required this.api,
    required this.journalFactory,
    this.pollInterval = const Duration(seconds: 15),
  }) {
    api.session.addListener(_sessionChanged);
  }
  AuthSession get session => api.session;
  bool get _eligible =>
      !_disposed &&
      _foreground &&
      session.isAuthenticated &&
      session.userId != null &&
      session.deviceId != null;
  String? get _currentOwner =>
      session.userId == null || session.deviceId == null
          ? null
          : '${session.userId}:${session.deviceId}';

  void setForeground(bool value) {
    if (_foreground == value || _disposed) return;
    _foreground = value;
    _restart();
  }

  void _sessionChanged() {
    if (_owner != _currentOwner || !_eligible) _restart();
  }

  void _restart() {
    _generation++;
    _owner = _currentOwner;
    _timer?.cancel();
    _failures = 0;
    lastError = null;
    if (!_eligible) {
      _setState(SyncState.stopped);
      return;
    }
    _schedule(Duration.zero);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    if (_eligible) {
      _timer = Timer(delay, () {
        synchronizeNow();
      });
    }
  }

  bool _valid(int generation, String owner) =>
      _eligible && generation == _generation && owner == _currentOwner;
  Future<void> synchronizeNow() {
    if (!_eligible) return Future.value();
    // Share the ongoing cycle instead of running a second storage/network loop.
    return _inFlight ??= _cycle().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> _cycle() async {
    final generation = _generation;
    final owner = _currentOwner!;
    final journal = _journals.putIfAbsent(
      owner,
      () => journalFactory(session.userId!, session.deviceId!),
    );
    _timer?.cancel();
    _setState(SyncState.syncing);
    try {
      Object? outgoingError;
      try {
        await journal.flush(api);
      } catch (error) {
        outgoingError = error;
      }
      if (!_valid(generation, owner)) return;
      final conversations = await session.getJson('conversations');
      if (conversations is! List) {
        throw const FormatException('Invalid conversation list');
      }
      for (final conversation in conversations) {
        if (!_valid(generation, owner)) return;
        if (conversation is! Map || conversation['id'] is! String) {
          throw const FormatException('Invalid conversation');
        }
        // Bound each cycle; further batches are fetched by the next cycle.
        for (var batch = 0; batch < 5; batch++) {
          if (!_valid(generation, owner)) return;
          final count = await journal.receive(
            api,
            conversation['id'] as String,
          );
          if (count < 100) break;
        }
      }
      if (outgoingError != null) throw outgoingError;
      if (_valid(generation, owner)) {
        _failures = 0;
        lastError = null;
        _setState(SyncState.ready);
      }
    } catch (error) {
      if (_valid(generation, owner)) {
        _failures++;
        lastError = error;
        _setState(SyncState.retrying);
      }
    } finally {
      if (_eligible) {
        final delay =
            generation != _generation
                ? Duration.zero
                : _failures == 0
                ? pollInterval
                : Duration(seconds: min(120, 1 << min(_failures, 7)));
        _schedule(delay);
      }
    }
  }

  void _setState(SyncState value) {
    if (_disposed) return;
    state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    session.removeListener(_sessionChanged);
    super.dispose();
  }
}
