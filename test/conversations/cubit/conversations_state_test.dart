import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Conversation buildConversation({
    String id = 'c0',
    String title = 'A conversation',
  }) {
    return Conversation(
      id: id,
      title: title,
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );
  }

  group(ConversationsState, () {
    test('default state has no conversations', () {
      expect(ConversationsState().conversations, isEmpty);
    });

    test('copyWith carries previous values when args are omitted', () {
      final seeded = ConversationsState(conversations: [buildConversation()]);
      expect(seeded.copyWith(), equals(seeded));
    });

    test('copyWith replaces conversations', () {
      final seeded = ConversationsState(
        conversations: [buildConversation(id: 'a')],
      );
      final next = seeded.copyWith(
        conversations: [buildConversation(id: 'b')],
      );
      expect(next.conversations.single.id, 'b');
    });

    test('supports value equality', () {
      final c = buildConversation();
      expect(
        ConversationsState(conversations: [c]),
        equals(ConversationsState(conversations: [c])),
      );
      expect(
        ConversationsState(conversations: [c]),
        isNot(equals(ConversationsState())),
      );
    });
  });
}
