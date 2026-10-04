import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:guffsuff_mobile/services/message_sync_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'package:guffsuff_mobile/services/message_journal.dart';
import 'package:guffsuff_mobile/services/message_sync.dart';
import 'message_journal_test.dart' show JournalStorage;

class SyncSession extends AuthSession {
  bool signedIn = true;
  String owner = 'user';
  @override
  bool get isAuthenticated => signedIn;
  @override
  String? get userId => signedIn ? owner : null;
  @override
  String? get deviceId => signedIn ? 'device' : null;
  dynamic conversations = [
    {'id': 'conversation'},
  ];
  @override
  Future<dynamic> getJson(String path) async => conversations;
  void signOut() {
    signedIn = false;
    notifyListeners();
  }
}

class SyncJournal extends MessageJournal {
  int flushes = 0, receives = 0;
  bool fail = false;
  Completer<void>? gate;
  final counts = <int>[];
  SyncJournal()
    : super(storage: JournalStorage(), userId: 'user', deviceId: 'device');
  @override
  Future<void> flush(EnvelopeApi api) async {
    flushes++;
    if (gate != null) await gate!.future;
    if (fail) throw StateError('offline');
  }

  @override
  Future<int> receive(EnvelopeApi api, String conversationId) async {
    receives++;
    return counts.isEmpty ? 0 : counts.removeAt(0);
  }
}

void main() {
  MessageSync setup(SyncSession session, SyncJournal journal) => MessageSync(
    api: EnvelopeApi(session),
    journalFactory: (_, __) => journal,
    pollInterval: const Duration(hours: 1),
  );
  test('foreground cycle flushes then receives and reports ready', () async {
    final session = SyncSession();
    final journal = SyncJournal();
    final sync = setup(session, journal);
    sync.setForeground(true);
    await sync.synchronizeNow();
    expect(journal.flushes, 1);
    expect(journal.receives, 1);
    expect(sync.state, SyncState.ready);
    sync.dispose();
  });
  test('concurrent triggers share one cycle', () async {
    final journal = SyncJournal()..gate = Completer<void>();
    final sync = setup(SyncSession(), journal);
    sync.setForeground(true);
    final first = sync.synchronizeNow();
    final second = sync.synchronizeNow();
    expect(identical(first, second), true);
    journal.gate!.complete();
    await first;
    expect(journal.flushes, 1);
    sync.dispose();
  });
  test(
    'logout during flush prevents conversation downloads and receipts',
    () async {
      final session = SyncSession();
      final journal = SyncJournal()..gate = Completer<void>();
      final sync = setup(session, journal);
      sync.setForeground(true);
      final cycle = sync.synchronizeNow();
      session.signOut();
      journal.gate!.complete();
      await cycle;
      expect(journal.receives, 0);
      expect(sync.state, SyncState.stopped);
      sync.dispose();
    },
  );
  test('pause during flush stops subsequent network stages', () async {
    final journal = SyncJournal()..gate = Completer<void>();
    final sync = setup(SyncSession(), journal);
    sync.setForeground(true);
    final cycle = sync.synchronizeNow();
    sync.setForeground(false);
    journal.gate!.complete();
    await cycle;
    expect(journal.receives, 0);
    expect(sync.state, SyncState.stopped);
    sync.dispose();
  });
  test('failure remains visible and a later cycle recovers', () async {
    final journal = SyncJournal()..fail = true;
    final sync = setup(SyncSession(), journal);
    sync.setForeground(true);
    await sync.synchronizeNow();
    expect(sync.state, SyncState.retrying);
    expect(sync.lastError, isA<StateError>());
    expect(journal.receives, 1);
    journal.fail = false;
    await sync.synchronizeNow();
    expect(sync.state, SyncState.ready);
    expect(sync.lastError, isNull);
    sync.dispose();
  });
  test('full batches drain only to the five-batch cycle bound', () async {
    final journal = SyncJournal()..counts.addAll(List.filled(6, 100));
    final sync = setup(SyncSession(), journal);
    sync.setForeground(true);
    await sync.synchronizeNow();
    expect(journal.receives, 5);
    expect(journal.counts.length, 1);
    sync.dispose();
  });
  test(
    'signed-out synchronization does not touch journal or network',
    () async {
      final session = SyncSession()..signedIn = false;
      final journal = SyncJournal();
      final sync = setup(session, journal);
      sync.setForeground(true);
      await sync.synchronizeNow();
      expect(journal.flushes, 0);
      expect(sync.state, SyncState.stopped);
      sync.dispose();
    },
  );
  testWidgets(
    'app lifecycle pauses synchronization and resume starts another cycle',
    (tester) async {
      final journal = SyncJournal();
      final sync = setup(SyncSession(), journal);
      await tester.pumpWidget(
        MessageSyncLifecycle(sync: sync, child: const SizedBox()),
      );
      await tester.pump(const Duration(milliseconds: 1));
      final beforePause = journal.flushes;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 1));
      expect(sync.state, SyncState.stopped);
      await tester.pump(const Duration(seconds: 30));
      expect(journal.flushes, beforePause);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 1));
      expect(journal.flushes, greaterThan(beforePause));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
