import 'dart:async';

import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chat_client/chat_client.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(MessageRole.user);
  });

  group(ChatBloc, () {
    const conversationId = 'c0';

    late MockConversationsRepository conversationsRepository;
    late MockChatRepository chatRepository;
    late MockChatRepositoryRegistry chatRepositoryRegistry;
    late StreamController<List<Message>> messagesController;

    Message buildMessage({
      String id = 'm0',
      MessageRole role = MessageRole.user,
      String text = 'hi',
    }) {
      return Message(
        id: id,
        conversationId: conversationId,
        role: role,
        text: text,
        sentAt: DateTime.utc(2026, 4, 27),
      );
    }

    setUp(() {
      conversationsRepository = MockConversationsRepository();
      chatRepository = MockChatRepository();
      chatRepositoryRegistry = MockChatRepositoryRegistry();
      messagesController = StreamController<List<Message>>.broadcast();

      when(
        () => conversationsRepository.watchMessages(any()),
      ).thenAnswer((_) => messagesController.stream);
      when(
        () => conversationsRepository.appendMessage(
          conversationId: any(named: 'conversationId'),
          role: any(named: 'role'),
          text: any(named: 'text'),
        ),
      ).thenAnswer(
        (invocation) async => buildMessage(
          role: invocation.namedArguments[#role] as MessageRole,
          text: invocation.namedArguments[#text] as String,
        ),
      );
      when(() => chatRepository.send(any())).thenAnswer((_) async {});
      when(() => chatRepositoryRegistry.obtain(any())).thenAnswer(
        (_) async => chatRepository,
      );
    });

    tearDown(() async {
      await messagesController.close();
    });

    ChatBloc buildBloc() => ChatBloc(
      conversationId: conversationId,
      conversationsRepository: conversationsRepository,
      chatRepositoryRegistry: chatRepositoryRegistry,
    );

    test('initial state is empty with no transient error', () {
      expect(buildBloc().state, ChatState());
    });

    test('subscribes to watchMessages with the conversation id', () {
      buildBloc();
      verify(() => conversationsRepository.watchMessages(conversationId))
          .called(1);
    });

    group(ChatMessagesUpdated, () {
      blocTest<ChatBloc, ChatState>(
        'updates state when watchMessages emits',
        build: buildBloc,
        act: (_) => messagesController.add([buildMessage()]),
        expect: () => [
          ChatState(messages: [buildMessage()]),
        ],
      );
    });

    group(ChatMessageSubmitted, () {
      blocTest<ChatBloc, ChatState>(
        'is a no-op when text is blank',
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('   ')),
        expect: () => <ChatState>[],
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

      blocTest<ChatBloc, ChatState>(
        'is a no-op while awaitingResponse is true',
        build: buildBloc,
        seed: () => ChatState(
          messages: [buildMessage()],
        ),
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => <ChatState>[],
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

      blocTest<ChatBloc, ChatState>(
        'persists the trimmed user message and forwards it to the repository',
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('  hi  ')),
        expect: () => <ChatState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.appendMessage(
              conversationId: conversationId,
              role: MessageRole.user,
              text: 'hi',
            ),
          ).called(1);
          verify(() => chatRepositoryRegistry.obtain(conversationId)).called(1);
          verify(() => chatRepository.send('hi')).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits persistenceFailed when appendMessage throws',
        setUp: () {
          when(
            () => conversationsRepository.appendMessage(
              conversationId: any(named: 'conversationId'),
              role: any(named: 'role'),
              text: any(named: 'text'),
            ),
          ).thenThrow(StateError('drift exploded'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => [
          ChatState(transientError: ChatTransientError.persistenceFailed),
        ],
        verify: (_) {
          verifyNever(() => chatRepository.send(any()));
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits connectionFailed when the registry rejects',
        setUp: () {
          when(() => chatRepositoryRegistry.obtain(any())).thenThrow(
            ConnectException('boom'),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => [
          ChatState(transientError: ChatTransientError.connectionFailed),
        ],
        verify: (_) {
          verifyNever(() => chatRepository.send(any()));
        },
      );

      blocTest<ChatBloc, ChatState>(
        'emits messageTooLarge when send rejects oversized payloads',
        setUp: () {
          when(() => chatRepository.send(any())).thenThrow(
            MessageTooLargeException('too large'),
          );
        },
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => [
          ChatState(transientError: ChatTransientError.messageTooLarge),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits sendFailed for other transport errors',
        setUp: () {
          when(() => chatRepository.send(any()))
              .thenThrow(SendException('not connected'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => [
          ChatState(transientError: ChatTransientError.sendFailed),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'clears a previous transient error after successful persistence',
        build: buildBloc,
        seed: () => ChatState(transientError: ChatTransientError.sendFailed),
        act: (bloc) => bloc.add(ChatMessageSubmitted('hi')),
        expect: () => [ChatState()],
      );
    });

    group(ChatTransientErrorCleared, () {
      blocTest<ChatBloc, ChatState>(
        'clears the transient error',
        build: buildBloc,
        seed: () => ChatState(transientError: ChatTransientError.sendFailed),
        act: (bloc) => bloc.add(ChatTransientErrorCleared()),
        expect: () => [ChatState()],
      );
    });

    group('close', () {
      test('cancels the messages subscription', () async {
        final bloc = buildBloc();
        await bloc.close();
        expect(messagesController.hasListener, isFalse);
      });
    });
  });
}
