import 'package:conversations_client/conversations_client.dart';
import 'package:equatable/equatable.dart';

/// {@template conversation}
/// A persisted chat conversation.
///
/// A conversation belongs to at most one [Folder]; a `null` [folderId]
/// means it lives in the implicit "Uncategorized" bucket.
/// {@endtemplate}
class Conversation extends Equatable {
  /// {@macro conversation}
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
  });

  /// Stable identifier, unique across all conversations.
  final String id;

  /// Identifier of the [Folder] this conversation belongs to, or `null`
  /// if it is uncategorized.
  final String? folderId;

  /// Display title shown in the conversation list.
  ///
  /// Auto-generated from the first user message on creation; may be
  /// overridden by the user via the rename action.
  final String title;

  /// Moment the conversation was created.
  final DateTime createdAt;

  /// Moment the conversation was last touched (typically when a new
  /// message was appended). Used to sort the conversation list.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, folderId, title, createdAt, updatedAt];
}
