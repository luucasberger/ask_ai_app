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

  Folder buildFolder({
    String id = 'f0',
    String name = 'A folder',
  }) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  group(ConversationsState, () {
    test(
      'default state has no conversations, no folders, and no transient error',
      () {
        final state = ConversationsState();
        expect(state.conversations, isEmpty);
        expect(state.folders, isEmpty);
        expect(state.transientError, isNull);
      },
    );

    test('copyWith carries previous values when args are omitted', () {
      final seeded = ConversationsState(
        conversations: [buildConversation()],
        folders: [buildFolder()],
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

    test('copyWith replaces folders', () {
      final seeded = ConversationsState(folders: [buildFolder(id: 'a')]);
      final next = seeded.copyWith(folders: [buildFolder(id: 'b')]);
      expect(next.folders.single.id, 'b');
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
      final f = buildFolder();
      expect(
        ConversationsState(conversations: [c], folders: [f]),
        equals(ConversationsState(conversations: [c], folders: [f])),
      );
      expect(
        ConversationsState(conversations: [c]),
        isNot(equals(ConversationsState())),
      );
      expect(
        ConversationsState(folders: [f]),
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
