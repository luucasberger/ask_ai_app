part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once when [AppBloc] is created to load any persisted
/// last-active conversation id.
final class AppStarted extends AppEvent {
  const AppStarted();
}

/// Dispatched when the user picks a conversation from the drawer.
final class AppConversationActivated extends AppEvent {
  const AppConversationActivated(this.conversationId);

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Dispatched when the user taps "New chat" in the drawer. Clears the
/// active conversation; the next user submission creates a new
/// [Conversation] row.
final class AppNewConversationRequested extends AppEvent {
  const AppNewConversationRequested();
}

/// Dispatched by the empty-state composer when the user submits the
/// first message in a brand-new conversation. The handler creates
/// the [Conversation] row, persists the user message, activates the
/// new conversation, and forwards the message to the chat backend.
final class AppFirstMessageSubmitted extends AppEvent {
  const AppFirstMessageSubmitted(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Dispatched by the [ChatRepositoryRegistry] subscription whenever
/// the chat backend echoes a message back for [conversationId].
final class AppEchoReceived extends AppEvent {
  const AppEchoReceived({required this.conversationId, required this.text});

  final String conversationId;
  final String text;

  @override
  List<Object?> get props => [conversationId, text];
}

/// Dispatched by the chat view when the typewriter has finished
/// revealing the assistant message identified by [messageId].
final class AppStreamingCompleted extends AppEvent {
  const AppStreamingCompleted(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Dispatched by the chat view after a transient error has been
/// surfaced to the user (e.g. shown as a snackbar).
final class AppTransientErrorCleared extends AppEvent {
  const AppTransientErrorCleared();
}
