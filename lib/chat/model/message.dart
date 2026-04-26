import 'package:equatable/equatable.dart';

/// Author of a [Message].
enum MessageRole {
  /// A message authored by the local user.
  user,

  /// A message authored by the AI assistant (echoed back over the WebSocket).
  assistant,
}

/// {@template message}
/// A single message in a conversation.
///
/// [text] is always the full final payload — the typewriter reveal is a
/// view-layer effect and is not modeled here.
/// {@endtemplate}
class Message extends Equatable {
  /// {@macro message}
  const Message({
    required this.id,
    required this.role,
    required this.text,
  });

  /// Stable identifier within a conversation. Unique per chat-bloc instance.
  final String id;

  /// Whether the message was authored by the user or the assistant.
  final MessageRole role;

  /// The full message text.
  final String text;

  @override
  List<Object?> get props => [id, role, text];
}
