part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once when the [ChatBloc] is created to open the connection
/// and begin observing incoming messages.
final class ChatStarted extends ChatEvent {
  const ChatStarted();
}

/// Dispatched when the user submits [text] from the composer.
final class ChatMessageSubmitted extends ChatEvent {
  const ChatMessageSubmitted(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Dispatched whenever the underlying [ChatRepository] emits a message
/// string from the backend. Named distinctly from `chat_client`'s own
/// `ChatMessageReceived` to avoid an import-level ambiguity in callers
/// that depend on both libraries.
final class ChatBackendMessageReceived extends ChatEvent {
  const ChatBackendMessageReceived(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Dispatched by the view when the typewriter has finished revealing the
/// assistant message identified by [messageId]. Clears the in-flight
/// indicator on the composer.
final class ChatStreamingCompleted extends ChatEvent {
  const ChatStreamingCompleted(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}
