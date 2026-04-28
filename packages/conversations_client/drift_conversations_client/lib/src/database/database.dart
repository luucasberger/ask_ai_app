import 'package:drift/drift.dart';
import 'package:drift_conversations_client/src/database/tables.dart';

part 'database.g.dart';

/// Drift database backing the conversations client. Owns the schema
/// and foreign-key configuration.
@DriftDatabase(tables: [Folders, Conversations, Messages, AppMetadata])
class ConversationsDatabase extends _$ConversationsDatabase {
  /// Builds a database against the given query executor. Pass
  /// `NativeDatabase.memory()` for tests; pass a file-backed executor
  /// at the application data directory in production.
  ConversationsDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // ISO8601 text storage preserves timezone information across
  // roundtrips; the default integer-epoch encoding silently drops it
  // and reads back as local time.
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(
    storeDateTimeAsText: true,
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
