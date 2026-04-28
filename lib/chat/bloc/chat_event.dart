part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched whenever the [ConversationsRepository] emits an updated
/// list of messages for the bloc's conversation.
final class ChatMessagesUpdated extends ChatEvent {
  const ChatMessagesUpdated(this.messages);

  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

/// Dispatched when the user submits [text] from the composer.
final class ChatMessageSubmitted extends ChatEvent {
  const ChatMessageSubmitted(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Dispatched by the view after a transient error has been surfaced
/// to the user (e.g. shown as a snackbar).
final class ChatTransientErrorCleared extends ChatEvent {
  const ChatTransientErrorCleared();
}
