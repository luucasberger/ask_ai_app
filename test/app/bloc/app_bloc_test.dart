import 'dart:async';

import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:ask_ai_app/app/registry/chat_repository_registry.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chat_client/chat_client.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _FakeChatRepository extends Fake implements ChatRepository {
  @override
  Stream<String> get incomingMessages => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> send(String message) async {}
}

class _ThrowingConnectChatRepository extends Fake implements ChatRepository {
  _ThrowingConnectChatRepository(this.exception);

  final ChatClientException exception;

  @override
  Stream<String> get incomingMessages => const Stream.empty();

  @override
  Future<void> connect() async => throw exception;

  @override
  Future<void> disconnect() async {}
}

class _ThrowingSendChatRepository extends Fake implements ChatRepository {
  _ThrowingSendChatRepository(this.exception);

  final ChatClientException exception;

  @override
  Stream<String> get incomingMessages => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> send(String message) async => throw exception;
}

class _LiveChatRepository extends Fake implements ChatRepository {
  _LiveChatRepository();

  final _controller = StreamController<String>.broadcast();

  void addEcho(String text) => _controller.add(text);

  @override
  Stream<String> get incomingMessages => _controller.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {
    await _controller.close();
  }
}

void main() {
  group(AppBloc, () {
    late MockConversationsRepository conversationsRepository;

    setUpAll(() {
      registerFallbackValue(MessageRole.user);
    });

    setUp(() {
      conversationsRepository = MockConversationsRepository();
      when(
        () => conversationsRepository.readMetadata(any()),
      ).thenAnswer((_) async => null);
      when(
        () => conversationsRepository.writeMetadata(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
    });

    ChatRepositoryRegistry buildRegistry({ChatRepositoryFactory? factory}) {
      final registry = ChatRepositoryRegistry(
        factory: factory ?? (_) => _FakeChatRepository(),
      );
      addTearDown(registry.disposeAll);
      return registry;
    }

    AppBloc buildBloc({ChatRepositoryFactory? factory}) => AppBloc(
      conversationsRepository: conversationsRepository,
      chatRepositoryRegistry: buildRegistry(factory: factory),
    );

    test('initial state has no active conversation and no streaming', () {
      expect(
        buildBloc().state,
        AppState(),
      );
    });

    group(AppStarted, () {
      blocTest<AppBloc, AppState>(
        'is a no-op when no last-active id is stored',
        build: buildBloc,
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => <AppState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.readMetadata(
              lastActiveConversationKey,
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'activates the persisted last-active id when present',
        setUp: () {
          when(
            () => conversationsRepository.readMetadata(any()),
          ).thenAnswer((_) async => 'c-1');
        },
        build: buildBloc,
        act: (bloc) => bloc.add(AppStarted()),
        expect: () => [
          AppState(activeConversationId: 'c-1'),
        ],
      );
    });

    group(AppConversationActivated, () {
      blocTest<AppBloc, AppState>(
        'sets the active conversation id and persists it',
        build: buildBloc,
        act: (bloc) => bloc.add(AppConversationActivated('c-1')),
        expect: () => [
          AppState(activeConversationId: 'c-1'),
        ],
        verify: (_) {
          verify(
            () => conversationsRepository.writeMetadata(
              key: lastActiveConversationKey,
              value: 'c-1',
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'clears any in-flight streaming id when switching conversations',
        seed: () => AppState(
          activeConversationId: 'c-1',
          streamingMessageId: 'm-1',
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(AppConversationActivated('c-2')),
        expect: () => [
          AppState(activeConversationId: 'c-2'),
        ],
      );
    });

    group(AppNewConversationRequested, () {
      blocTest<AppBloc, AppState>(
        'clears active conversation id and persisted last-active',
        seed: () => AppState(activeConversationId: 'c-1'),
        build: buildBloc,
        act: (bloc) => bloc.add(AppNewConversationRequested()),
        expect: () => [AppState()],
        verify: (_) {
          verify(
            () => conversationsRepository.writeMetadata(
              key: lastActiveConversationKey,
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'clears any in-flight streaming id',
        seed: () => AppState(
          activeConversationId: 'c-1',
          streamingMessageId: 'm-1',
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(AppNewConversationRequested()),
        expect: () => [AppState()],
      );
    });

    group(AppFirstMessageSubmitted, () {
      final newConversation = Conversation(
        id: 'c-new',
        title: 'hi there',
        createdAt: DateTime.utc(2026, 4, 27),
        updatedAt: DateTime.utc(2026, 4, 27),
      );
      final userMessage = Message(
        id: 'm-1',
        conversationId: 'c-new',
        role: MessageRole.user,
        text: 'hi there',
        sentAt: DateTime.utc(2026, 4, 27),
      );

      void stubPersistence() {
        when(
          () => conversationsRepository.createConversation(
            title: any(named: 'title'),
            folderId: any(named: 'folderId'),
          ),
        ).thenAnswer((_) async => newConversation);
        when(
          () => conversationsRepository.appendMessage(
            conversationId: any(named: 'conversationId'),
            role: any(named: 'role'),
            text: any(named: 'text'),
          ),
        ).thenAnswer((_) async => userMessage);
      }

      blocTest<AppBloc, AppState>(
        'is a no-op when text is blank',
        build: buildBloc,
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('   ')),
        expect: () => <AppState>[],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.createConversation(
              title: any(named: 'title'),
            ),
          );
        },
      );

      blocTest<AppBloc, AppState>(
        'creates the conversation, persists the user message, '
        'activates it, and forwards the trimmed text to the repository',
        setUp: stubPersistence,
        build: buildBloc,
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('  hi there  ')),
        expect: () => [AppState(activeConversationId: 'c-new')],
        verify: (_) {
          verify(
            () => conversationsRepository.createConversation(
              title: 'hi there',
            ),
          ).called(1);
          verify(
            () => conversationsRepository.appendMessage(
              conversationId: 'c-new',
              role: MessageRole.user,
              text: 'hi there',
            ),
          ).called(1);
          verify(
            () => conversationsRepository.writeMetadata(
              key: lastActiveConversationKey,
              value: 'c-new',
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'clears any pre-existing transient error and streaming id when '
        'activating the new conversation',
        seed: () => AppState(
          streamingMessageId: 'old',
          transientError: AppTransientError.sendFailed,
        ),
        setUp: stubPersistence,
        build: buildBloc,
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [AppState(activeConversationId: 'c-new')],
      );

      blocTest<AppBloc, AppState>(
        'surfaces persistenceFailed when createConversation throws',
        setUp: () {
          when(
            () => conversationsRepository.createConversation(
              title: any(named: 'title'),
              folderId: any(named: 'folderId'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [
          AppState(transientError: AppTransientError.persistenceFailed),
        ],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          );
        },
      );

      blocTest<AppBloc, AppState>(
        'surfaces persistenceFailed when appendMessage throws',
        setUp: () {
          when(
            () => conversationsRepository.createConversation(
              title: any(named: 'title'),
              folderId: any(named: 'folderId'),
            ),
          ).thenAnswer((_) async => newConversation);
          when(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [
          AppState(transientError: AppTransientError.persistenceFailed),
        ],
      );

      blocTest<AppBloc, AppState>(
        'surfaces connectionFailed when the chat repository fails to connect',
        setUp: stubPersistence,
        build: () => buildBloc(
          factory: (_) =>
              _ThrowingConnectChatRepository(ConnectException('no')),
        ),
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [
          AppState(activeConversationId: 'c-new'),
          AppState(
            activeConversationId: 'c-new',
            transientError: AppTransientError.connectionFailed,
          ),
        ],
      );

      blocTest<AppBloc, AppState>(
        'surfaces messageTooLarge when send rejects oversized payloads',
        setUp: stubPersistence,
        build: () => buildBloc(
          factory: (_) => _ThrowingSendChatRepository(
            MessageTooLargeException('too large'),
          ),
        ),
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [
          AppState(activeConversationId: 'c-new'),
          AppState(
            activeConversationId: 'c-new',
            transientError: AppTransientError.messageTooLarge,
          ),
        ],
      );

      blocTest<AppBloc, AppState>(
        'surfaces sendFailed for other transport errors on send',
        setUp: stubPersistence,
        build: () => buildBloc(
          factory: (_) => _ThrowingSendChatRepository(SendException('nope')),
        ),
        act: (bloc) => bloc.add(AppFirstMessageSubmitted('hi')),
        expect: () => [
          AppState(activeConversationId: 'c-new'),
          AppState(
            activeConversationId: 'c-new',
            transientError: AppTransientError.sendFailed,
          ),
        ],
      );
    });

    group(AppEchoReceived, () {
      final assistantMessage = Message(
        id: 'm-9',
        conversationId: 'c-1',
        role: MessageRole.assistant,
        text: 'hi',
        sentAt: DateTime.utc(2026, 4, 26),
      );

      blocTest<AppBloc, AppState>(
        'persists the assistant message and sets streaming id when active',
        seed: () => AppState(activeConversationId: 'c-1'),
        setUp: () {
          when(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          ).thenAnswer((_) async => assistantMessage);
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(AppEchoReceived(conversationId: 'c-1', text: 'hi')),
        expect: () => [
          AppState(
            activeConversationId: 'c-1',
            streamingMessageId: 'm-9',
          ),
        ],
        verify: (_) {
          verify(
            () => conversationsRepository.appendMessage(
              conversationId: 'c-1',
              role: MessageRole.assistant,
              text: 'hi',
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'persists without setting streaming when conversation is not active',
        seed: () => AppState(activeConversationId: 'c-2'),
        setUp: () {
          when(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          ).thenAnswer((_) async => assistantMessage);
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(AppEchoReceived(conversationId: 'c-1', text: 'hi')),
        expect: () => <AppState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.appendMessage(
              conversationId: 'c-1',
              role: MessageRole.assistant,
              text: 'hi',
            ),
          ).called(1);
        },
      );

      blocTest<AppBloc, AppState>(
        'surfaces persistenceFailed when appendMessage throws',
        seed: () => AppState(activeConversationId: 'c-1'),
        setUp: () {
          when(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(AppEchoReceived(conversationId: 'c-1', text: 'hi')),
        expect: () => [
          AppState(
            activeConversationId: 'c-1',
            transientError: AppTransientError.persistenceFailed,
          ),
        ],
      );
    });

    group(AppStreamingCompleted, () {
      blocTest<AppBloc, AppState>(
        'clears streaming id when ids match',
        seed: () => AppState(
          activeConversationId: 'c-1',
          streamingMessageId: 'm-1',
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(AppStreamingCompleted('m-1')),
        expect: () => [AppState(activeConversationId: 'c-1')],
      );

      blocTest<AppBloc, AppState>(
        'is a no-op when ids do not match',
        seed: () => AppState(
          activeConversationId: 'c-1',
          streamingMessageId: 'm-1',
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(AppStreamingCompleted('m-other')),
        expect: () => <AppState>[],
      );
    });

    group(AppTransientErrorCleared, () {
      blocTest<AppBloc, AppState>(
        'clears the transient error',
        seed: () => AppState(
          transientError: AppTransientError.persistenceFailed,
        ),
        build: buildBloc,
        act: (bloc) => bloc.add(AppTransientErrorCleared()),
        expect: () => [AppState()],
      );
    });

    group('echo wiring', () {
      test('forwards registry echoes as $AppEchoReceived events', () async {
        final repo = _LiveChatRepository();
        final assistantMessage = Message(
          id: 'm',
          conversationId: 'c-1',
          role: MessageRole.assistant,
          text: 'hi',
          sentAt: DateTime.utc(2026, 4, 26),
        );
        when(
          () => conversationsRepository.appendMessage(
            conversationId: any(named: 'conversationId'),
            role: any(named: 'role'),
            text: any(named: 'text'),
          ),
        ).thenAnswer((_) async => assistantMessage);

        final registry = buildRegistry(factory: (_) => repo);
        final bloc = AppBloc(
          conversationsRepository: conversationsRepository,
          chatRepositoryRegistry: registry,
        );
        addTearDown(bloc.close);

        await registry.obtain('c-1');
        repo.addEcho('hi');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => conversationsRepository.appendMessage(
            conversationId: 'c-1',
            role: MessageRole.assistant,
            text: 'hi',
          ),
        ).called(1);
      });
    });

    group('event equality', () {
      test('$AppStarted supports value equality', () {
        expect(AppStarted(), equals(AppStarted()));
        expect(AppStarted().props, isEmpty);
      });

      test('$AppConversationActivated supports value equality', () {
        expect(
          AppConversationActivated('c'),
          equals(AppConversationActivated('c')),
        );
        expect(
          AppConversationActivated('a'),
          isNot(equals(AppConversationActivated('b'))),
        );
        expect(AppConversationActivated('c').props, ['c']);
      });

      test('$AppNewConversationRequested supports value equality', () {
        expect(
          AppNewConversationRequested(),
          equals(AppNewConversationRequested()),
        );
      });

      test('$AppFirstMessageSubmitted supports value equality', () {
        expect(
          AppFirstMessageSubmitted('hi'),
          equals(AppFirstMessageSubmitted('hi')),
        );
        expect(
          AppFirstMessageSubmitted('hi'),
          isNot(equals(AppFirstMessageSubmitted('bye'))),
        );
        expect(AppFirstMessageSubmitted('hi').props, ['hi']);
      });

      test('$AppEchoReceived supports value equality', () {
        const a = AppEchoReceived(conversationId: 'c', text: 'hi');
        const b = AppEchoReceived(conversationId: 'c', text: 'hi');
        const c = AppEchoReceived(conversationId: 'c', text: 'bye');
        expect(a, equals(b));
        expect(a, isNot(equals(c)));
        expect(a.props, ['c', 'hi']);
      });

      test('$AppStreamingCompleted supports value equality', () {
        expect(AppStreamingCompleted('m'), equals(AppStreamingCompleted('m')));
        expect(
          AppStreamingCompleted('a'),
          isNot(equals(AppStreamingCompleted('b'))),
        );
        expect(AppStreamingCompleted('m').props, ['m']);
      });

      test('$AppTransientErrorCleared supports value equality', () {
        expect(
          AppTransientErrorCleared(),
          equals(AppTransientErrorCleared()),
        );
      });
    });

    group('autoTitle', () {
      test('returns the trimmed message when within the limit', () {
        expect(AppBloc.autoTitle('  hello world  '), 'hello world');
      });

      test('truncates with ellipsis when longer than 40 chars', () {
        final long = 'a' * 50;
        expect(AppBloc.autoTitle(long), '${'a' * 40}…');
      });
    });

    group(AppState, () {
      test('copyWith honors clear flags', () {
        final populated = AppState(
          activeConversationId: 'c',
          streamingMessageId: 'm',
          transientError: AppTransientError.persistenceFailed,
        );

        expect(
          populated.copyWith(clearActiveConversationId: true),
          AppState(
            streamingMessageId: 'm',
            transientError: AppTransientError.persistenceFailed,
          ),
        );
        expect(
          populated.copyWith(clearStreamingMessageId: true),
          AppState(
            activeConversationId: 'c',
            transientError: AppTransientError.persistenceFailed,
          ),
        );
        expect(
          populated.copyWith(clearTransientError: true),
          AppState(
            activeConversationId: 'c',
            streamingMessageId: 'm',
          ),
        );
      });
    });
  });
}
