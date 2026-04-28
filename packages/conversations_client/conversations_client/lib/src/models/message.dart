import 'package:equatable/equatable.dart';

/// Author of a [Message].
enum MessageRole {
  /// A message authored by the local user.
  user,

  /// A message authored by the AI assistant (echoed back over the
  /// chat backend).
  assistant,
}

/// {@template message}
/// A single message inside a conversation.
///
/// [text] is always the full final payload — the typewriter reveal is a
/// view-layer effect and is not modeled here.
/// {@endtemplate}
class Message extends Equatable {
  /// {@macro message}
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.text,
    required this.sentAt,
  });

  /// Stable identifier within the persistence layer.
  final String id;

  /// Identifier of the parent conversation.
  final String conversationId;

  /// Whether the message was authored by the user or the assistant.
  final MessageRole role;

  /// The full message text.
  final String text;

  /// Moment the message was appended to the conversation.
  final DateTime sentAt;

  @override
  List<Object?> get props => [id, conversationId, role, text, sentAt];
}
