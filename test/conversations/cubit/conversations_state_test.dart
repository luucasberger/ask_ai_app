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
    test('default state has no conversations and no transient error', () {
      const state = ConversationsState();
      expect(state.conversations, isEmpty);
      expect(state.transientError, isNull);
    });

    test('copyWith carries previous values when args are omitted', () {
      final seeded = ConversationsState(
        conversations: [buildConversation()],
        transientError: ConversationsTransientError.renameFailed,
      );
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

    test('copyWith sets transientError when provided', () {
      final next = ConversationsState().copyWith(
        transientError: ConversationsTransientError.renameFailed,
      );
      expect(next.transientError, ConversationsTransientError.renameFailed);
    });

    test('copyWith clears transientError when clearTransientError is true', () {
      final seeded = ConversationsState(
        transientError: ConversationsTransientError.renameFailed,
      );
      expect(seeded.copyWith(clearTransientError: true).transientError, isNull);
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
      expect(
        ConversationsState(
          transientError: ConversationsTransientError.renameFailed,
        ),
        isNot(equals(ConversationsState())),
      );
    });
  });
}
