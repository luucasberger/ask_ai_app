import 'dart:async';

import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:ask_ai_app/chat/model/message.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chat_client/chat_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group(ChatBloc, () {
    late MockChatRepository chatRepository;
    late StreamController<String> incoming;

    setUp(() {
      chatRepository = MockChatRepository();
      incoming = StreamController<String>.broadcast();
      when(() => chatRepository.incomingMessages).thenAnswer(
        (_) => incoming.stream,
      );
      when(chatRepository.connect).thenAnswer((_) async {});
      when(chatRepository.disconnect).thenAnswer((_) async {});
      when(() => chatRepository.send(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await incoming.close();
    });

    Future<void> waitForReady(ChatBloc bloc) => bloc.stream.firstWhere(
          (s) => s.status == ChatStatus.ready,
        );

    ChatBloc buildBloc() => ChatBloc(chatRepository: chatRepository);

    test('initial state has status initial and no messages', () {
      expect(buildBloc().state, ChatState());
    });

    group(ChatStarted, () {
      blocTest<ChatBloc, ChatState>(
        'transitions connecting → ready when connect succeeds',
        build: buildBloc,
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
        ],
        verify: (_) {
          verify(chatRepository.connect).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'transitions to error with connectionFailed when connect throws',
        setUp: () {
          when(chatRepository.connect).thenThrow(ConnectException('boom'));
        },
        build: buildBloc,
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(
            status: ChatStatus.error,
            transientError: ChatTransientError.connectionFailed,
          ),
        ],
      );
    });

    group('incoming messages', () {
      blocTest<ChatBloc, ChatState>(
        'appends an assistant message and sets streamingMessageId',
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          incoming.add('hello');
        },
        wait: Duration(milliseconds: 20),
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.assistant, text: 'hello'),
            ],
            streamingMessageId: '0',
          ),
        ],
      );
    });

    group(ChatMessageSubmitted, () {
      blocTest<ChatBloc, ChatState>(
        'appends the user message and marks awaitingResponse',
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          bloc.add(ChatMessageSubmitted('  hi  '));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'hi'),
            ],
            awaitingResponse: true,
          ),
        ],
        verify: (_) {
          verify(() => chatRepository.send('hi')).called(1);
        },
      );

      blocTest<ChatBloc, ChatState>(
        'is a no-op when text is blank',
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          bloc.add(ChatMessageSubmitted('   '));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
        ],
        verify: (_) {
          verifyNever(() => chatRepository.send(any()));
        },
      );

      blocTest<ChatBloc, ChatState>(
        'is a no-op while not in a sendable state',
        setUp: () {
          when(chatRepository.connect).thenThrow(ConnectException('boom'));
        },
        build: buildBloc,
        act: (bloc) async {
          await bloc.stream
              .firstWhere((state) => state.status == ChatStatus.error);
          bloc.add(ChatMessageSubmitted('hi'));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(
            status: ChatStatus.error,
            transientError: ChatTransientError.connectionFailed,
          ),
        ],
        verify: (_) {
          verifyNever(() => chatRepository.send(any()));
        },
      );

      blocTest<ChatBloc, ChatState>(
        'surfaces messageTooLarge when send rejects oversized payloads',
        setUp: () {
          when(() => chatRepository.send(any())).thenThrow(
            MessageTooLargeException('too large'),
          );
        },
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          bloc.add(ChatMessageSubmitted('hi'));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'hi'),
            ],
            awaitingResponse: true,
          ),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'hi'),
            ],
            transientError: ChatTransientError.messageTooLarge,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'surfaces sendFailed for other transport errors',
        setUp: () {
          when(() => chatRepository.send(any()))
              .thenThrow(SendException('not connected'));
        },
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          bloc.add(ChatMessageSubmitted('hi'));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'hi'),
            ],
            awaitingResponse: true,
          ),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'hi'),
            ],
            transientError: ChatTransientError.sendFailed,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'clears a previous transientError on a fresh send',
        setUp: () {
          var calls = 0;
          when(() => chatRepository.send(any())).thenAnswer((_) async {
            if (calls++ == 0) throw SendException('first');
          });
        },
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          bloc.add(ChatMessageSubmitted('first'));
          await bloc.stream.firstWhere(
            (state) => state.transientError == ChatTransientError.sendFailed,
          );
          bloc.add(ChatMessageSubmitted('second'));
        },
        skip: 4,
        expect: () => [
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.user, text: 'first'),
              Message(id: '1', role: MessageRole.user, text: 'second'),
            ],
            awaitingResponse: true,
          ),
        ],
      );
    });

    group('ChatStreamingCompleted', () {
      blocTest<ChatBloc, ChatState>(
        'clears streamingMessageId when ids match',
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          incoming.add('hello');
          await bloc.stream
              .firstWhere((state) => state.streamingMessageId == '0');
          bloc.add(ChatStreamingCompleted('0'));
        },
        skip: 3,
        expect: () => [
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.assistant, text: 'hello'),
            ],
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'is a no-op when ids do not match',
        build: buildBloc,
        act: (bloc) async {
          await waitForReady(bloc);
          incoming.add('hello');
          await bloc.stream.firstWhere(
            (state) => state.streamingMessageId == '0',
          );
          bloc.add(ChatStreamingCompleted('other'));
        },
        expect: () => [
          ChatState(status: ChatStatus.connecting),
          ChatState(status: ChatStatus.ready),
          ChatState(
            status: ChatStatus.ready,
            messages: const [
              Message(id: '0', role: MessageRole.assistant, text: 'hello'),
            ],
            streamingMessageId: '0',
          ),
        ],
      );
    });

    group('close', () {
      test('cancels the incoming subscription and disconnects', () async {
        final bloc = ChatBloc(chatRepository: chatRepository);
        await waitForReady(bloc);
        await bloc.close();
        verify(chatRepository.disconnect).called(1);
      });
    });

    group(ChatState, () {
      test('canSend is true only when ready and no response in flight', () {
        expect(ChatState(status: ChatStatus.ready).canSend, isTrue);
        expect(ChatState(status: ChatStatus.connecting).canSend, isFalse);
        expect(
          ChatState(status: ChatStatus.ready, awaitingResponse: true).canSend,
          isFalse,
        );
        expect(
          ChatState(status: ChatStatus.ready, streamingMessageId: '0').canSend,
          isFalse,
        );
      });

      test('isResponseInFlight reflects awaiting + streaming', () {
        expect(ChatState().isResponseInFlight, isFalse);
        expect(ChatState(awaitingResponse: true).isResponseInFlight, isTrue);
        expect(
          ChatState(streamingMessageId: '0').isResponseInFlight,
          isTrue,
        );
      });

      test('copyWith honors clear flags', () {
        final seeded = ChatState(
          streamingMessageId: '1',
          transientError: ChatTransientError.sendFailed,
        );
        expect(
          seeded.copyWith(clearStreamingMessageId: true).streamingMessageId,
          isNull,
        );
        expect(
          seeded.copyWith(clearTransientError: true).transientError,
          isNull,
        );
      });
    });

    group('events', () {
      test('expose value equality', () {
        expect(ChatStarted(), equals(ChatStarted()));
        expect(
          ChatMessageSubmitted('a'),
          equals(ChatMessageSubmitted('a')),
        );
        expect(
          ChatBackendMessageReceived('a'),
          equals(ChatBackendMessageReceived('a')),
        );
        expect(
          ChatStreamingCompleted('1'),
          equals(ChatStreamingCompleted('1')),
        );
      });
    });
  });
}
