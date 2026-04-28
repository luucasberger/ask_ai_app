import 'package:conversations_client/conversations_client.dart';
import 'package:drift/drift.dart';
import 'package:drift_conversations_client/src/database/database.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String _defaultIdGenerator() => _uuid.v4();

/// {@template drift_conversations_client}
/// Drift-backed implementation of [ConversationsClient].
///
/// The constructor takes a [QueryExecutor] so callers can wire up
/// either a file-backed `NativeDatabase` (production) or an in-memory
/// database (tests). Construct one and dispose with [close] when the
/// app shuts down.
/// {@endtemplate}
class DriftConversationsClient implements ConversationsClient {
  /// {@macro drift_conversations_client}
  DriftConversationsClient({
    required QueryExecutor executor,
    @visibleForTesting DateTime Function() now = DateTime.now,
    @visibleForTesting String Function() idGenerator = _defaultIdGenerator,
  }) : _db = ConversationsDatabase(executor),
       _now = now,
       _idGenerator = idGenerator;

  final ConversationsDatabase _db;
  final DateTime Function() _now;
  final String Function() _idGenerator;

  /// Closes the underlying database. Call once during app shutdown.
  Future<void> close() => _db.close();

  @override
  Stream<List<Conversation>> watchConversations() {
    final query = _db.select(_db.conversations)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().map<List<Conversation>>(
      (rows) => rows.map(_toConversation).toList(growable: false),
    );
  }

  @override
  Stream<List<Folder>> watchFolders() {
    final query = _db.select(_db.folders)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map<List<Folder>>(
      (rows) => rows.map(_toFolder).toList(growable: false),
    );
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    final query = _db.select(_db.messages)
      ..where((t) => t.conversationId.equals(conversationId))
      ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]);
    return query.watch().map<List<Message>>(
      (rows) => rows.map(_toMessage).toList(growable: false),
    );
  }

  @override
  Future<Conversation> createConversation({
    required String title,
    String? folderId,
  }) async {
    try {
      final now = _now();
      final row = await _db
          .into(_db.conversations)
          .insertReturning(
            ConversationsCompanion.insert(
              id: _idGenerator(),
              title: title,
              folderId: Value(folderId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return _toConversation(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> renameConversation({
    required String id,
    required String title,
  }) async {
    try {
      final query = _db.update(_db.conversations)
        ..where((t) => t.id.equals(id));
      await query.write(
        ConversationsCompanion(
          title: Value(title),
          updatedAt: Value(_now()),
        ),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      final query = _db.delete(_db.conversations)
        ..where((t) => t.id.equals(id));
      await query.go();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> moveConversation({
    required String id,
    String? folderId,
  }) async {
    try {
      final query = _db.update(_db.conversations)
        ..where((t) => t.id.equals(id));
      await query.write(
        ConversationsCompanion(
          folderId: Value(folderId),
          updatedAt: Value(_now()),
        ),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<Message> appendMessage({
    required String conversationId,
    required MessageRole role,
    required String text,
  }) async {
    try {
      return await _db.transaction(() async {
        final now = _now();
        final row = await _db
            .into(_db.messages)
            .insertReturning(
              MessagesCompanion.insert(
                id: _idGenerator(),
                conversationId: conversationId,
                role: role.name,
                content: text,
                sentAt: now,
              ),
            );
        final touch = _db.update(_db.conversations)
          ..where((t) => t.id.equals(conversationId));
        await touch.write(ConversationsCompanion(updatedAt: Value(now)));
        return _toMessage(row);
      });
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<Folder> createFolder(String name) async {
    try {
      final row = await _db
          .into(_db.folders)
          .insertReturning(
            FoldersCompanion.insert(
              id: _idGenerator(),
              name: name,
              createdAt: _now(),
            ),
          );
      return _toFolder(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> renameFolder({required String id, required String name}) async {
    try {
      final query = _db.update(_db.folders)..where((t) => t.id.equals(id));
      await query.write(FoldersCompanion(name: Value(name)));
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    try {
      final query = _db.delete(_db.folders)..where((t) => t.id.equals(id));
      await query.go();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<int> conversationCountInFolder(String folderId) async {
    try {
      final count = countAll();
      final query = _db.selectOnly(_db.conversations)
        ..addColumns([count])
        ..where(_db.conversations.folderId.equals(folderId));
      final row = await query.getSingle();
      return row.read(count) ?? 0;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<String?> readMetadata(String key) async {
    try {
      final query = _db.select(_db.appMetadata)
        ..where((t) => t.key.equals(key));
      final row = await query.getSingleOrNull();
      return row?.value;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  @override
  Future<void> writeMetadata({required String key, String? value}) async {
    try {
      if (value == null) {
        final query = _db.delete(_db.appMetadata)
          ..where((t) => t.key.equals(key));
        await query.go();
        return;
      }
      await _db
          .into(_db.appMetadata)
          .insertOnConflictUpdate(
            AppMetadataCompanion.insert(key: key, value: Value(value)),
          );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(StorageException(error), stackTrace);
    }
  }

  Conversation _toConversation(ConversationRow row) => Conversation(
    id: row.id,
    folderId: row.folderId,
    title: row.title,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Folder _toFolder(FolderRow row) =>
      Folder(id: row.id, name: row.name, createdAt: row.createdAt);

  Message _toMessage(MessageRow row) => Message(
    id: row.id,
    conversationId: row.conversationId,
    role: _parseRole(row.role),
    text: row.content,
    sentAt: row.sentAt,
  );

  MessageRole _parseRole(String stored) => MessageRole.values.firstWhere(
    (role) => role.name == stored,
    orElse: () => MessageRole.assistant,
  );
}
