import 'package:conversations_client/conversations_client.dart';
import 'package:test/test.dart';

void main() {
  group(Conversation, () {
    final createdAt = DateTime.utc(2026, 4, 26, 12);
    final updatedAt = DateTime.utc(2026, 4, 26, 13);
    final conversation = Conversation(
      id: 'c1',
      title: 'Books',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('exposes its fields', () {
      expect(conversation.id, equals('c1'));
      expect(conversation.title, equals('Books'));
      expect(conversation.createdAt, equals(createdAt));
      expect(conversation.updatedAt, equals(updatedAt));
      expect(conversation.folderId, isNull);
    });

    test('folderId can be supplied', () {
      final scoped = Conversation(
        id: 'c1',
        title: 'Books',
        createdAt: createdAt,
        updatedAt: updatedAt,
        folderId: 'f1',
      );
      expect(scoped.folderId, equals('f1'));
    });

    test('supports value equality', () {
      expect(
        conversation,
        equals(
          Conversation(
            id: 'c1',
            title: 'Books',
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ),
      );
    });

    test('different folderId values are not equal', () {
      final a = Conversation(
        id: 'c1',
        title: 'Books',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final b = Conversation(
        id: 'c1',
        title: 'Books',
        createdAt: createdAt,
        updatedAt: updatedAt,
        folderId: 'f1',
      );
      expect(a, isNot(equals(b)));
    });

    test('props include every field', () {
      expect(
        conversation.props,
        orderedEquals([
          conversation.id,
          conversation.folderId,
          conversation.title,
          conversation.createdAt,
          conversation.updatedAt,
        ]),
      );
    });
  });
}
