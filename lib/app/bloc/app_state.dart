part of 'app_bloc.dart';

/// Categories of one-shot errors surfaced from [AppBloc] for UI to
/// display.
enum AppTransientError {
  /// Persisting a message (or creating a conversation) failed.
  persistenceFailed,

  /// Obtaining the [ChatRepository] for the conversation failed
  /// because the underlying transport could not connect.
  connectionFailed,

  /// Sending a message over the chat backend failed for an
  /// unspecified transport reason.
  sendFailed,

  /// The user attempted to send a message that exceeded the
  /// transport size limit.
  messageTooLarge,

  /// Deleting a conversation failed in the storage layer.
  deleteFailed,
}

/// {@template app_state}
/// The state managed by [AppBloc].
/// {@endtemplate}
final class AppState extends Equatable {
  /// {@macro app_state}
  const AppState({
    this.activeConversationId,
    this.streamingMessageId,
    this.transientError,
  });

  /// Identifier of the conversation the user is currently viewing, or
  /// `null` if a new (not-yet-persisted) chat is in progress.
  final String? activeConversationId;

  /// Identifier of the assistant message currently being revealed by
  /// the typewriter for the active conversation, or `null` when no
  /// reveal is in progress.
  final String? streamingMessageId;

  /// A transient error to surface (e.g. via snackbar). Cleared once
  /// observed via [AppTransientErrorCleared].
  final AppTransientError? transientError;

  AppState copyWith({
    String? activeConversationId,
    String? streamingMessageId,
    AppTransientError? transientError,
    bool clearActiveConversationId = false,
    bool clearStreamingMessageId = false,
    bool clearTransientError = false,
  }) {
    return AppState(
      activeConversationId: clearActiveConversationId
          ? null
          : activeConversationId ?? this.activeConversationId,
      streamingMessageId: clearStreamingMessageId
          ? null
          : streamingMessageId ?? this.streamingMessageId,
      transientError:
          clearTransientError ? null : transientError ?? this.transientError,
    );
  }

  @override
  List<Object?> get props => [
        activeConversationId,
        streamingMessageId,
        transientError,
      ];
}
