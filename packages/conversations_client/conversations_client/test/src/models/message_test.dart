import 'package:conversations_client/conversations_client.dart';
import 'package:test/test.dart';

void main() {
  group(Message, () {
    final sentAt = DateTime.utc(2026, 4, 26, 12);
    final message = Message(
      id: 'm1',
      conversationId: 'c1',
      role: MessageRole.user,
      text: 'hello',
      sentAt: sentAt,
    );

    test('exposes its fields', () {
      expect(message.id, equals('m1'));
      expect(message.conversationId, equals('c1'));
      expect(message.role, equals(MessageRole.user));
      expect(message.text, equals('hello'));
      expect(message.sentAt, equals(sentAt));
    });

    test('supports value equality', () {
      expect(
        message,
        equals(
          Message(
            id: 'm1',
            conversationId: 'c1',
            role: MessageRole.user,
            text: 'hello',
            sentAt: sentAt,
          ),
        ),
      );
    });

    test('different role values are not equal', () {
      final assistant = Message(
        id: 'm1',
        conversationId: 'c1',
        role: MessageRole.assistant,
        text: 'hello',
        sentAt: sentAt,
      );
      expect(message, isNot(equals(assistant)));
    });

    test('props include every field', () {
      expect(
        message.props,
        orderedEquals([
          message.id,
          message.conversationId,
          message.role,
          message.text,
          message.sentAt,
        ]),
      );
    });

    test('exposes both $MessageRole values', () {
      expect(
        MessageRole.values,
        orderedEquals([MessageRole.user, MessageRole.assistant]),
      );
    });
  });
}
