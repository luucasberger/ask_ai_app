import 'package:conversations_client/conversations_client.dart';
import 'package:test/test.dart';

void main() {
  group(Folder, () {
    final createdAt = DateTime.utc(2026, 4, 26, 12);
    final folder = Folder(id: 'f1', name: 'Books', createdAt: createdAt);

    test('exposes its fields', () {
      expect(folder.id, equals('f1'));
      expect(folder.name, equals('Books'));
      expect(folder.createdAt, equals(createdAt));
    });

    test('supports value equality', () {
      expect(
        folder,
        equals(Folder(id: 'f1', name: 'Books', createdAt: createdAt)),
      );
    });

    test('different ids are not equal', () {
      expect(
        folder,
        isNot(equals(Folder(id: 'f2', name: 'Books', createdAt: createdAt))),
      );
    });

    test('props include every field', () {
      expect(
        folder.props,
        orderedEquals([folder.id, folder.name, folder.createdAt]),
      );
    });
  });
}
