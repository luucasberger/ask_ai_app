import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ChatMessagesUpdated, () {
    final a = Message(
      id: '0',
      conversationId: 'c',
      role: MessageRole.user,
      text: 'hi',
      sentAt: DateTime.utc(2026, 4, 27),
    );
    final b = Message(
      id: '1',
      conversationId: 'c',
      role: MessageRole.assistant,
      text: 'hi',
      sentAt: DateTime.utc(2026, 4, 27),
    );

    test('supports value equality', () {
      expect(ChatMessagesUpdated([a]), equals(ChatMessagesUpdated([a])));
      expect(ChatMessagesUpdated([a]), isNot(equals(ChatMessagesUpdated([b]))));
    });
  });

  group(ChatMessageSubmitted, () {
    test('supports value equality', () {
      expect(ChatMessageSubmitted('a'), equals(ChatMessageSubmitted('a')));
      expect(
        ChatMessageSubmitted('a'),
        isNot(equals(ChatMessageSubmitted('b'))),
      );
    });
  });

  group(ChatTransientErrorCleared, () {
    test('supports value equality', () {
      expect(
        ChatTransientErrorCleared(),
        equals(ChatTransientErrorCleared()),
      );
    });
  });
}
