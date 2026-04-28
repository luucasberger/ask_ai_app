import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Message buildMessage({
    String id = 'm0',
    MessageRole role = MessageRole.user,
    String text = 'hi',
  }) {
    return Message(
      id: id,
      conversationId: 'c0',
      role: role,
      text: text,
      sentAt: DateTime.utc(2026, 4, 27),
    );
  }

  group(ChatState, () {
    test('default state is empty with no transient error', () {
      final state = ChatState();
      expect(state.messages, isEmpty);
      expect(state.transientError, isNull);
      expect(state.awaitingResponse, isFalse);
    });

    test('awaitingResponse is true when the last message is from the user', () {
      expect(
        ChatState(messages: [buildMessage()]).awaitingResponse,
        isTrue,
      );
    });

    test(
      'awaitingResponse is false when the last message is from the assistant',
      () {
        expect(
          ChatState(messages: [buildMessage(role: MessageRole.assistant)])
              .awaitingResponse,
          isFalse,
        );
      },
    );

    test('copyWith carries over previous values when args are omitted', () {
      final seeded = ChatState(
        messages: [buildMessage()],
        transientError: ChatTransientError.sendFailed,
      );
      expect(seeded.copyWith(), equals(seeded));
    });

    test('copyWith honors clearTransientError', () {
      final seeded = ChatState(transientError: ChatTransientError.sendFailed);
      expect(
        seeded.copyWith(clearTransientError: true).transientError,
        isNull,
      );
    });

    test('supports value equality', () {
      final m = buildMessage();
      expect(
        ChatState(
          messages: [m],
          transientError: ChatTransientError.sendFailed,
        ),
        equals(
          ChatState(
            messages: [m],
            transientError: ChatTransientError.sendFailed,
          ),
        ),
      );
      expect(
        ChatState(messages: [m]),
        isNot(equals(ChatState())),
      );
    });
  });
}
