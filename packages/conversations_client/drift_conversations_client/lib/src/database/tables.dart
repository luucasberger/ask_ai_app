// Drift requires a public column getter per table column; documenting
// each one would be pure noise.
// ignore_for_file: public_member_api_docs

import 'package:drift/drift.dart';

/// User-created folder grouping conversations. Folders are flat; they
/// cannot contain other folders.
@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A persisted chat conversation. [folderId] is nullable; a `null`
/// value means the conversation lives in the "Uncategorized" bucket.
@DataClassName('ConversationRow')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().customConstraint(
    'NULL REFERENCES folders(id) ON DELETE CASCADE',
  )();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single message inside a conversation. Deleting the parent
/// conversation cascades and removes every message belonging to it.
@DataClassName('MessageRow')
class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().customConstraint(
    'NOT NULL REFERENCES conversations(id) ON DELETE CASCADE',
  )();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get sentAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Free-form key/value table for storing app-level metadata that
/// doesn't merit its own table (e.g. last active conversation id).
@DataClassName('AppMetadataRow')
class AppMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
