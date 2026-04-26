import 'dart:async';

import 'package:ask_ai_app/chat/model/message.dart';
import 'package:bloc/bloc.dart';
import 'package:chat_client/chat_client.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:equatable/equatable.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// {@template chat_bloc}
/// Owns the chat conversation surface: opens the [ChatRepository]
/// connection on creation, listens for incoming messages, exposes the
/// composed message list, and tracks the in-flight indicator that the
/// composer renders.
///
/// The bloc holds the full final text of every message; the typewriter
/// reveal is a view-layer effect coordinated through
/// [ChatStreamingCompleted].
/// {@endtemplate}
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  /// {@macro chat_bloc}
  ChatBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
    on<ChatBackendMessageReceived>(_onBackendMessageReceived);
    on<ChatStreamingCompleted>(_onStreamingCompleted);
  }

  final ChatRepository _chatRepository;
  StreamSubscription<String>? _incomingMessagesSubscription;
  int _idSeed = 0;

  String _nextMessageId() => '${_idSeed++}';

  Future<void> _onStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.connecting));
    try {
      await _chatRepository.connect();
    } on ChatClientException {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          transientError: ChatTransientError.connectionFailed,
        ),
      );
      return;
    }

    _incomingMessagesSubscription = _chatRepository.incomingMessages.listen(
      (text) => add(ChatBackendMessageReceived(text)),
    );
    emit(state.copyWith(status: ChatStatus.ready));
  }

  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty || !state.canSend) return;

    final userMessage = Message(
      id: _nextMessageId(),
      role: MessageRole.user,
      text: trimmed,
    );
    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        awaitingResponse: true,
        clearTransientError: true,
      ),
    );

    try {
      await _chatRepository.send(trimmed);
    } on MessageTooLargeException {
      emit(
        state.copyWith(
          awaitingResponse: false,
          transientError: ChatTransientError.messageTooLarge,
        ),
      );
    } on ChatClientException {
      emit(
        state.copyWith(
          awaitingResponse: false,
          transientError: ChatTransientError.sendFailed,
        ),
      );
    }
  }

  void _onBackendMessageReceived(
    ChatBackendMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final assistantMessage = Message(
      id: _nextMessageId(),
      role: MessageRole.assistant,
      text: event.text,
    );
    emit(
      state.copyWith(
        messages: [...state.messages, assistantMessage],
        awaitingResponse: false,
        streamingMessageId: assistantMessage.id,
      ),
    );
  }

  void _onStreamingCompleted(
    ChatStreamingCompleted event,
    Emitter<ChatState> emit,
  ) {
    if (state.streamingMessageId != event.messageId) return;
    emit(state.copyWith(clearStreamingMessageId: true));
  }

  @override
  Future<void> close() async {
    await _incomingMessagesSubscription?.cancel();
    await _chatRepository.disconnect();
    return super.close();
  }
}
