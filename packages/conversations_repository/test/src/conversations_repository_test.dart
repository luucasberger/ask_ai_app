import 'package:conversations_repository/conversations_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockConversationsClient extends Mock implements ConversationsClient {}

void main() {
  late _MockConversationsClient client;
  late ConversationsRepository repository;

  setUpAll(() {
    registerFallbackValue(MessageRole.user);
  });

  setUp(() {
    client = _MockConversationsClient();
    repository = ConversationsRepository(client: client);
  });

  group(ConversationsRepository, () {
    final now = DateTime.utc(2026, 4, 26, 12);

    test('can be instantiated with a $ConversationsClient', () {
      expect(repository, isNotNull);
    });

    test('watchConversations delegates to the client', () {
      final expected = Stream<List<Conversation>>.value([
        Conversation(
          id: 'c',
          title: 't',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      when(client.watchConversations).thenAnswer((_) => expected);

      expect(repository.watchConversations(), same(expected));
      verify(client.watchConversations).called(1);
    });

    test('watchFolders delegates to the client', () {
      final expected = Stream<List<Folder>>.value([
        Folder(id: 'f', name: 'n', createdAt: now),
      ]);
      when(client.watchFolders).thenAnswer((_) => expected);

      expect(repository.watchFolders(), same(expected));
      verify(client.watchFolders).called(1);
    });

    test('watchMessages forwards conversationId', () {
      final expected = Stream<List<Message>>.value(<Message>[]);
      when(() => client.watchMessages(any())).thenAnswer((_) => expected);

      expect(repository.watchMessages('c1'), same(expected));
      verify(() => client.watchMessages('c1')).called(1);
    });

    test('createConversation forwards title and folderId', () async {
      final expected = Conversation(
        id: 'c',
        title: 't',
        createdAt: now,
        updatedAt: now,
        folderId: 'f',
      );
      when(
        () => client.createConversation(
          title: any(named: 'title'),
          folderId: any(named: 'folderId'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await repository.createConversation(
        title: 't',
        folderId: 'f',
      );

      expect(result, same(expected));
      verify(
        () => client.createConversation(title: 't', folderId: 'f'),
      ).called(1);
    });

    test('renameConversation forwards id and title', () async {
      when(
        () => client.renameConversation(
          id: any(named: 'id'),
          title: any(named: 'title'),
        ),
      ).thenAnswer((_) async {});

      await repository.renameConversation(id: 'c', title: 't');

      verify(
        () => client.renameConversation(id: 'c', title: 't'),
      ).called(1);
    });

    test('deleteConversation forwards id', () async {
      when(() => client.deleteConversation(any())).thenAnswer((_) async {});

      await repository.deleteConversation('c');

      verify(() => client.deleteConversation('c')).called(1);
    });

    test('moveConversation forwards id and folderId', () async {
      when(
        () => client.moveConversation(
          id: any(named: 'id'),
          folderId: any(named: 'folderId'),
        ),
      ).thenAnswer((_) async {});

      await repository.moveConversation(id: 'c', folderId: 'f');

      verify(
        () => client.moveConversation(id: 'c', folderId: 'f'),
      ).called(1);
    });

    test('appendMessage forwards every argument', () async {
      final expected = Message(
        id: 'm',
        conversationId: 'c',
        role: MessageRole.user,
        text: 'hi',
        sentAt: now,
      );
      when(
        () => client.appendMessage(
          conversationId: any(named: 'conversationId'),
          role: any(named: 'role'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await repository.appendMessage(
        conversationId: 'c',
        role: MessageRole.user,
        text: 'hi',
      );

      expect(result, same(expected));
      verify(
        () => client.appendMessage(
          conversationId: 'c',
          role: MessageRole.user,
          text: 'hi',
        ),
      ).called(1);
    });

    test('createFolder forwards name', () async {
      final expected = Folder(id: 'f', name: 'Reading', createdAt: now);
      when(() => client.createFolder(any())).thenAnswer((_) async => expected);

      final result = await repository.createFolder('Reading');

      expect(result, same(expected));
      verify(() => client.createFolder('Reading')).called(1);
    });

    test('renameFolder forwards id and name', () async {
      when(
        () => client.renameFolder(
          id: any(named: 'id'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async {});

      await repository.renameFolder(id: 'f', name: 'New');

      verify(() => client.renameFolder(id: 'f', name: 'New')).called(1);
    });

    test('deleteFolder forwards id', () async {
      when(() => client.deleteFolder(any())).thenAnswer((_) async {});

      await repository.deleteFolder('f');

      verify(() => client.deleteFolder('f')).called(1);
    });

    test('conversationCountInFolder forwards folderId', () async {
      when(
        () => client.conversationCountInFolder(any()),
      ).thenAnswer((_) async => 5);

      expect(await repository.conversationCountInFolder('f'), equals(5));
      verify(() => client.conversationCountInFolder('f')).called(1);
    });

    test('readMetadata forwards key', () async {
      when(() => client.readMetadata(any())).thenAnswer((_) async => 'v');

      expect(await repository.readMetadata('k'), equals('v'));
      verify(() => client.readMetadata('k')).called(1);
    });

    test('writeMetadata forwards key and value', () async {
      when(
        () => client.writeMetadata(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await repository.writeMetadata(key: 'k', value: 'v');

      verify(() => client.writeMetadata(key: 'k', value: 'v')).called(1);
    });
  });
}
