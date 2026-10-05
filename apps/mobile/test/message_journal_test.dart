import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:guffsuff_mobile/services/auth_session.dart';
import 'package:guffsuff_mobile/services/envelope_api.dart';
import 'package:guffsuff_mobile/services/message_journal.dart';
import 'package:guffsuff_mobile/services/secure_storage.dart';

class JournalStorage extends SecureStorageService {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> readMessageJournal(String scope) async => values[scope];
  @override
  Future<void> writeMessageJournal(String scope, String value) async {
    if (fail) throw StateError('Disk failure');
    values[scope] = value;
  }
}

class Owner extends AuthSession {
  @override
  String get userId => 'user';
  @override
  String get deviceId => 'device';
  @override
  bool get isAuthenticated => true;
}

class FakeApi extends EnvelopeApi {
  final sent = <String>[];
  final receipts = <String>[];
  List<Map<String, dynamic>> incoming = [];
  bool failSend = false, failAck = false;
  FakeApi() : super(Owner());
  @override
  Future<Map<String, dynamic>> submit({
    required String conversationId,
    required String recipientUserId,
    required String idempotencyKey,
    required List<int> ciphertext,
    required DateTime createdAt,
    required DateTime expiresAt,
    int protocolVersion = 1,
  }) async {
    sent.add(idempotencyKey);
    if (failSend) throw StateError('Offline');
    return {'id': 'accepted'};
  }

  @override
  Future<List<Map<String, dynamic>>> pending(String conversationId) async =>
      incoming;
  @override
  Future<void> delivered(String envelopeId) async {
    receipts.add(envelopeId);
    if (failAck) throw StateError('Receipt lost');
  }
}

Map<String, dynamic> outgoing() => {
  'conversationId': 'conversation',
  'recipientUserId': 'peer',
  'idempotencyKey': 'stable-key',
  'opaquePayloadBase64': 'AQID',
  'protocolVersion': 1,
  'clientCreatedAt': '2026-10-03T00:00:00Z',
  'expiresAt': '2027-10-03T00:00:00Z',
};
Map<String, dynamic> incoming() => {
  'id': 'envelope',
  'conversation_id': 'conversation',
  'opaque_payload_base64': 'AQID\n',
};
MessageJournal journal(JournalStorage storage, {int maxBytes = 262144}) =>
    MessageJournal(
      storage: storage,
      userId: 'user',
      deviceId: 'device',
      maxBytes: maxBytes,
    );
void main() {
  test(
    'offline send survives new journal instance and keeps original retry key',
    () async {
      final storage = JournalStorage();
      final api = FakeApi()..failSend = true;
      await journal(storage).enqueue(outgoing());
      await expectLater(journal(storage).flush(api), throwsStateError);
      api.failSend = false;
      await journal(storage).flush(api);
      expect(api.sent, ['stable-key', 'stable-key']);
      await journal(storage).flush(api);
      expect(api.sent.length, 2);
    },
  );
  test(
    'failed local deletion after acceptance retries the identical envelope',
    () async {
      final storage = JournalStorage();
      final api = FakeApi();
      await journal(storage).enqueue(outgoing());
      storage.fail = true;
      await expectLater(journal(storage).flush(api), throwsStateError);
      storage.fail = false;
      await journal(storage).flush(api);
      expect(api.sent, ['stable-key', 'stable-key']);
    },
  );
  test('storage failure does not acknowledge incoming ciphertext', () async {
    final storage = JournalStorage()..fail = true;
    final api = FakeApi()..incoming = [incoming()];
    await expectLater(
      journal(storage).receive(api, 'conversation'),
      throwsStateError,
    );
    expect(api.receipts, isEmpty);
  });
  test(
    'lost receipt retries without duplicating persisted ciphertext',
    () async {
      final storage = JournalStorage();
      final api =
          FakeApi()
            ..incoming = [incoming()]
            ..failAck = true;
      await expectLater(
        journal(storage).receive(api, 'conversation'),
        throwsStateError,
      );
      api.failAck = false;
      await journal(storage).receive(api, 'conversation');
      expect((await journal(storage).inbox()).length, 1);
      expect(api.receipts, ['envelope', 'envelope']);
      expect(
        (await journal(storage).inbox()).single['opaque_payload_base64'],
        'AQID',
      );
    },
  );
  test(
    'bounded storage fails before acknowledging instead of dropping data',
    () async {
      final storage = JournalStorage();
      final api = FakeApi()..incoming = [incoming()];
      await expectLater(
        journal(storage, maxBytes: 10).receive(api, 'conversation'),
        throwsStateError,
      );
      expect(api.receipts, isEmpty);
    },
  );
  test('corrupt journal fails closed and is not overwritten', () async {
    final storage = JournalStorage();
    final j = journal(storage);
    storage.values[j.scope] = '{broken';
    await expectLater(j.enqueue(outgoing()), throwsFormatException);
    expect(storage.values[j.scope], '{broken');
  });
  test('concurrent enqueue calls preserve both entries', () async {
    final storage = JournalStorage();
    final j = journal(storage);
    await Future.wait([
      j.enqueue(outgoing()),
      j.enqueue({...outgoing(), 'idempotencyKey': 'second'}),
    ]);
    final state = jsonDecode(storage.values[j.scope]!);
    expect((state['outbox'] as List).length, 2);
  });
  test('retry key cannot be rebound to different ciphertext', () async {
    final storage = JournalStorage();
    final j = journal(storage);
    await j.enqueue(outgoing());
    await expectLater(
      j.enqueue({...outgoing(), 'opaquePayloadBase64': 'BA=='}),
      throwsStateError,
    );
    await j.enqueue(outgoing());
    expect((jsonDecode(storage.values[j.scope]!)['outbox'] as List).length, 1);
  });
  test(
    'other account journal cannot send or acknowledge through current session',
    () async {
      final storage = JournalStorage();
      final api = FakeApi();
      final j = MessageJournal(
        storage: storage,
        userId: 'another',
        deviceId: 'device',
      );
      await expectLater(j.flush(api), throwsStateError);
      await expectLater(j.receive(api, 'conversation'), throwsStateError);
      expect(api.sent, isEmpty);
      expect(api.receipts, isEmpty);
    },
  );
  test(
    'duplicate envelope ID with changed ciphertext is rejected without a new receipt',
    () async {
      final storage = JournalStorage();
      final api = FakeApi()..incoming = [incoming()];
      final j = journal(storage);
      await j.receive(api, 'conversation');
      api.incoming = [
        {...incoming(), 'opaque_payload_base64': 'BA=='},
      ];
      await expectLater(j.receive(api, 'conversation'), throwsFormatException);
      expect(api.receipts.length, 1);
      expect((await j.inbox()).single['opaque_payload_base64'], 'AQID');
    },
  );
}
