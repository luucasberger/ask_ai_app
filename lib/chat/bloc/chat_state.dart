part of 'chat_bloc.dart';

/// Categories of one-shot errors surfaced from [ChatBloc] for the
/// view to display.
enum ChatTransientError {
  /// Persisting the user's message into local storage failed.
  persistenceFailed,

  /// Obtaining the conversation's [ChatRepository] failed because the
  /// underlying transport could not connect.
  connectionFailed,

  /// Sending a message failed for an unspecified transport reason.
  sendFailed,

  /// The user attempted to send a message that exceeded the size limit.
  messageTooLarge,
}

/// {@template chat_state}
/// The state managed by [ChatBloc].
/// {@endtemplate}
final class ChatState extends Equatable {
  /// {@macro chat_state}
  const ChatState({this.messages = const [], this.transientError});

  /// Messages exchanged in the conversation, ordered oldest → newest,
  /// as observed from [ConversationsRepository.watchMessages].
  final List<Message> messages;

  /// A transient error to surface to the user (e.g. via snackbar).
  /// Cleared by the view via [ChatTransientErrorCleared] once observed.
  final ChatTransientError? transientError;

  /// Whether the conversation is currently waiting for an assistant
  /// echo. Derived structurally from [messages]: the conversation is
  /// awaiting iff the last message was authored by the user.
  bool get awaitingResponse =>
      messages.isNotEmpty && messages.last.role == MessageRole.user;

  ChatState copyWith({
    List<Message>? messages,
    ChatTransientError? transientError,
    bool clearTransientError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      transientError:
          clearTransientError ? null : transientError ?? this.transientError,
    );
  }

  @override
  List<Object?> get props => [messages, transientError];
}
