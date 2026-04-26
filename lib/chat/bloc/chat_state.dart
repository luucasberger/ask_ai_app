part of 'chat_bloc.dart';

enum ChatStatus {
  /// The bloc has been created but has not yet attempted to connect.
  initial,

  /// Connecting to the chat backend.
  connecting,

  /// Connected and ready to send/receive messages.
  ready,

  /// The connection attempt failed.
  error,
}

/// Categories of one-shot errors surfaced from [ChatBloc] for UI to display.
enum ChatTransientError {
  /// Connecting to the chat backend failed.
  connectionFailed,

  /// Sending a message failed for an unspecified reason.
  sendFailed,

  /// The user attempted to send a message exceeding the size limit.
  messageTooLarge,
}

/// {@template chat_state}
/// The state managed by [ChatBloc].
/// {@endtemplate}
final class ChatState extends Equatable {
  /// {@macro chat_state}
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.awaitingResponse = false,
    this.streamingMessageId,
    this.transientError,
  });

  /// Current connection status.
  final ChatStatus status;

  /// Messages exchanged in the conversation, ordered oldest → newest.
  final List<Message> messages;

  /// `true` between the moment the user submits a message and the moment the
  /// echoed assistant reply arrives from the backend.
  final bool awaitingResponse;

  /// Identifier of the assistant message currently being revealed by the
  /// typewriter, or `null` once the reveal completes.
  final String? streamingMessageId;

  /// A transient error to surface (e.g. via snackbar). Cleared once observed.
  final ChatTransientError? transientError;

  /// Whether the composer should display its in-flight indicator.
  bool get isResponseInFlight => awaitingResponse || streamingMessageId != null;

  /// Whether the composer is enabled for new submissions.
  bool get canSend => status == ChatStatus.ready && !isResponseInFlight;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    bool? awaitingResponse,
    String? streamingMessageId,
    ChatTransientError? transientError,
    bool clearStreamingMessageId = false,
    bool clearTransientError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      awaitingResponse: awaitingResponse ?? this.awaitingResponse,
      streamingMessageId: clearStreamingMessageId
          ? null
          : streamingMessageId ?? this.streamingMessageId,
      transientError:
          clearTransientError ? null : transientError ?? this.transientError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        awaitingResponse,
        streamingMessageId,
        transientError,
      ];
}
