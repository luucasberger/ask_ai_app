import 'package:conversations_client/conversations_client.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:drift_conversations_client/drift_conversations_client.dart';
import 'package:test/test.dart';

DriftConversationsClient _buildFailingClient() => DriftConversationsClient(
  executor: LazyDatabase(() => throw Exception('boom')),
  now: () => DateTime.utc(2026, 4, 26),
  idGenerator: () => 'id',
);

void main() {
  group(DriftConversationsClient, () {
    late DriftConversationsClient client;
    late DateTime now;
    late int idSeed;

    setUp(() {
      now = DateTime.utc(2026, 4, 26, 12);
      idSeed = 0;
      client = DriftConversationsClient(
        executor: NativeDatabase.memory(),
        now: () => now,
        idGenerator: () => 'id-${idSeed++}',
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('implements $ConversationsClient', () {
      expect(client, isA<ConversationsClient>());
    });

    test('default id generator produces UUIDs', () async {
      final defaults = DriftConversationsClient(
        executor: NativeDatabase.memory(),
      );
      addTearDown(defaults.close);

      final conversation = await defaults.createConversation(title: 'A');

      expect(
        conversation.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    group('createConversation', () {
      test('persists with the supplied title and timestamps', () async {
        final conversation = await client.createConversation(title: 'Books');

        expect(conversation.id, equals('id-0'));
        expect(conversation.title, equals('Books'));
        expect(conversation.folderId, isNull);
        expect(conversation.createdAt, equals(now));
        expect(conversation.updatedAt, equals(now));
      });

      test('respects the supplied folderId', () async {
        final folder = await client.createFolder('Reading');
        final conversation = await client.createConversation(
          title: 'Books',
          folderId: folder.id,
        );

        expect(conversation.folderId, equals(folder.id));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.createConversation(title: 'x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('watchConversations', () {
      test('orders by updatedAt descending', () async {
        await client.createConversation(title: 'Old');
        now = now.add(const Duration(minutes: 1));
        final newer = await client.createConversation(title: 'Newer');

        final conversations = await client.watchConversations().first;

        expect(conversations.first.id, equals(newer.id));
        expect(conversations.length, equals(2));
      });
    });

    group('renameConversation', () {
      test('updates the title and bumps updatedAt', () async {
        final created = await client.createConversation(title: 'Old');
        now = now.add(const Duration(hours: 1));

        await client.renameConversation(id: created.id, title: 'New');

        final conversations = await client.watchConversations().first;
        expect(conversations.single.title, equals('New'));
        expect(conversations.single.updatedAt, equals(now));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.renameConversation(id: 'x', title: 'y'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('deleteConversation', () {
      test('removes the conversation', () async {
        final created = await client.createConversation(title: 'Doomed');

        await client.deleteConversation(created.id);

        expect(await client.watchConversations().first, isEmpty);
      });

      test('cascades to messages', () async {
        final conversation = await client.createConversation(title: 'Doomed');
        await client.appendMessage(
          conversationId: conversation.id,
          role: MessageRole.user,
          text: 'hi',
        );

        await client.deleteConversation(conversation.id);

        expect(
          await client.watchMessages(conversation.id).first,
          isEmpty,
        );
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.deleteConversation('x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('moveConversation', () {
      test('moves the conversation into the supplied folder', () async {
        final folder = await client.createFolder('Reading');
        final conversation = await client.createConversation(title: 'Books');

        await client.moveConversation(id: conversation.id, folderId: folder.id);

        final conversations = await client.watchConversations().first;
        expect(conversations.single.folderId, folder.id);
      });

      test('moves to "Uncategorized" when folderId is null', () async {
        final folder = await client.createFolder('Reading');
        final conversation = await client.createConversation(
          title: 'Books',
          folderId: folder.id,
        );

        await client.moveConversation(id: conversation.id);

        final conversations = await client.watchConversations().first;
        expect(conversations.single.folderId, isNull);
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.moveConversation(id: 'x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('appendMessage', () {
      test(
        'returns the persisted message with assigned id and timestamp',
        () async {
          final conversation = await client.createConversation(title: 'Books');
          now = now.add(const Duration(minutes: 5));

          final message = await client.appendMessage(
            conversationId: conversation.id,
            role: MessageRole.user,
            text: 'hello',
          );

          expect(message.id, equals('id-1'));
          expect(message.conversationId, equals(conversation.id));
          expect(message.role, equals(MessageRole.user));
          expect(message.text, equals('hello'));
          expect(message.sentAt, equals(now));
        },
      );

      test('bumps the parent conversation updatedAt', () async {
        final conversation = await client.createConversation(title: 'Books');
        now = now.add(const Duration(minutes: 5));

        await client.appendMessage(
          conversationId: conversation.id,
          role: MessageRole.assistant,
          text: 'hi',
        );

        final conversations = await client.watchConversations().first;
        expect(conversations.single.updatedAt, equals(now));
      });

      test('throws $StorageException on FK violation', () async {
        await expectLater(
          () => client.appendMessage(
            conversationId: 'no-such-conversation',
            role: MessageRole.user,
            text: 'x',
          ),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('watchMessages', () {
      test(
        'orders by sentAt ascending and filters by conversationId',
        () async {
          final a = await client.createConversation(title: 'A');
          final b = await client.createConversation(title: 'B');

          now = now.add(const Duration(seconds: 1));
          await client.appendMessage(
            conversationId: a.id,
            role: MessageRole.user,
            text: 'a-1',
          );
          now = now.add(const Duration(seconds: 1));
          await client.appendMessage(
            conversationId: b.id,
            role: MessageRole.user,
            text: 'b-1',
          );
          now = now.add(const Duration(seconds: 1));
          await client.appendMessage(
            conversationId: a.id,
            role: MessageRole.assistant,
            text: 'a-2',
          );

          final aMessages = await client.watchMessages(a.id).first;
          expect(aMessages.map((m) => m.text), orderedEquals(['a-1', 'a-2']));
        },
      );

      test('persists assistant role roundtrip', () async {
        final conversation = await client.createConversation(title: 'A');
        await client.appendMessage(
          conversationId: conversation.id,
          role: MessageRole.assistant,
          text: 'hi',
        );

        final messages = await client.watchMessages(conversation.id).first;
        expect(messages.single.role, equals(MessageRole.assistant));
      });
    });

    group('createFolder', () {
      test('persists with the supplied name and timestamp', () async {
        final folder = await client.createFolder('Reading');

        expect(folder.id, equals('id-0'));
        expect(folder.name, equals('Reading'));
        expect(folder.createdAt, equals(now));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.createFolder('x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('watchFolders', () {
      test('orders by createdAt ascending', () async {
        await client.createFolder('Older');
        now = now.add(const Duration(minutes: 1));
        await client.createFolder('Newer');

        final folders = await client.watchFolders().first;

        expect(folders.map((f) => f.name), orderedEquals(['Older', 'Newer']));
      });
    });

    group('renameFolder', () {
      test('updates the folder name', () async {
        final folder = await client.createFolder('Old');

        await client.renameFolder(id: folder.id, name: 'New');

        final folders = await client.watchFolders().first;
        expect(folders.single.name, equals('New'));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.renameFolder(id: 'x', name: 'y'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('deleteFolder', () {
      test('cascades to conversations and their messages', () async {
        final folder = await client.createFolder('Doomed');
        final conversation = await client.createConversation(
          title: 'Inside',
          folderId: folder.id,
        );
        await client.appendMessage(
          conversationId: conversation.id,
          role: MessageRole.user,
          text: 'hi',
        );

        await client.deleteFolder(folder.id);

        expect(await client.watchFolders().first, isEmpty);
        expect(await client.watchConversations().first, isEmpty);
        expect(await client.watchMessages(conversation.id).first, isEmpty);
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.deleteFolder('x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('conversationCountInFolder', () {
      test('returns 0 for an empty folder', () async {
        final folder = await client.createFolder('Empty');

        expect(await client.conversationCountInFolder(folder.id), 0);
      });

      test('returns the count of conversations inside the folder', () async {
        final folder = await client.createFolder('Reading');
        await client.createConversation(title: 'A', folderId: folder.id);
        await client.createConversation(title: 'B', folderId: folder.id);
        await client.createConversation(title: 'Outside');

        expect(await client.conversationCountInFolder(folder.id), equals(2));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.conversationCountInFolder('x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('readMetadata', () {
      test('returns null when no value is stored', () async {
        expect(await client.readMetadata('missing'), isNull);
      });

      test('returns the previously written value', () async {
        await client.writeMetadata(key: 'k', value: 'v');

        expect(await client.readMetadata('k'), equals('v'));
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.readMetadata('x'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('writeMetadata', () {
      test('inserts a new value', () async {
        await client.writeMetadata(key: 'k', value: 'v');

        expect(await client.readMetadata('k'), equals('v'));
      });

      test('updates an existing value', () async {
        await client.writeMetadata(key: 'k', value: 'v1');
        await client.writeMetadata(key: 'k', value: 'v2');

        expect(await client.readMetadata('k'), equals('v2'));
      });

      test('removes the value when value is null', () async {
        await client.writeMetadata(key: 'k', value: 'v');
        await client.writeMetadata(key: 'k');

        expect(await client.readMetadata('k'), isNull);
      });

      test('throws $StorageException on storage failure', () async {
        final failing = _buildFailingClient();

        await expectLater(
          () => failing.writeMetadata(key: 'x', value: 'y'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('role parsing fallback', () {
      test(
        'unknown role values fall back to ${MessageRole.assistant}',
        () async {
          // Write a row directly via the executor with a role string the
          // client wouldn't normally produce, then verify the read path
          // maps it to the safe default rather than throwing.
          final executor = NativeDatabase.memory();
          final tampered = DriftConversationsClient(
            executor: executor,
            now: () => DateTime.utc(2026, 4, 26),
            idGenerator: () => 'id',
          );
          addTearDown(tampered.close);

          final conversation = await tampered.createConversation(title: 'A');
          await executor.runCustom(
            'INSERT INTO messages (id, conversation_id, role, content, '
            'sent_at) '
            'VALUES (?, ?, ?, ?, ?)',
            [
              'mystery',
              conversation.id,
              'mystery',
              'hi',
              DateTime.utc(2026, 4, 26).toIso8601String(),
            ],
          );

          final messages = await tampered.watchMessages(conversation.id).first;
          expect(messages.single.role, equals(MessageRole.assistant));
        },
      );
    });
  });
}
