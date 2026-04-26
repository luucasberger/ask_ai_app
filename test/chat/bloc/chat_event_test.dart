import 'package:ask_ai_app/chat/bloc/chat_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(ChatStarted, () {
    test('supports value equality', () {
      expect(ChatStarted(), equals(ChatStarted()));
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

  group(ChatBackendMessageReceived, () {
    test('supports value equality', () {
      expect(
        ChatBackendMessageReceived('a'),
        equals(ChatBackendMessageReceived('a')),
      );
      expect(
        ChatBackendMessageReceived('a'),
        isNot(equals(ChatBackendMessageReceived('b'))),
      );
    });
  });

  group(ChatStreamingCompleted, () {
    test('supports value equality', () {
      expect(ChatStreamingCompleted('1'), equals(ChatStreamingCompleted('1')));
      expect(
        ChatStreamingCompleted('1'),
        isNot(equals(ChatStreamingCompleted('2'))),
      );
    });
  });
}
