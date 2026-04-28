import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_client/chat_client.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:equatable/equatable.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// Signature for the function the [ChatBloc] uses to obtain the
/// [ChatRepository] for its conversation when a message needs to be
/// sent over the wire.
///
/// The app-level bloc supplies this hook (see
/// `AppBloc.obtainChatRepository`) so the connection lifecycle is
/// owned outside the chat surface — a per-conversation socket can
/// outlive any individual mount of the chat view.
typedef ChatRepositoryProvider = Future<ChatRepository> Function(
  String conversationId,
);

/// {@template chat_bloc}
/// Owns the chat surface for a single conversation.
///
/// Subscribes to [ConversationsRepository.watchMessages] for the
/// bloc's conversation id and forwards user submissions to the
/// conversation's [ChatRepository] (obtained on demand via
/// [ChatRepositoryProvider]). The user message is persisted before
/// the send so the UI reflects the user's intent immediately.
///
/// "Awaiting response" is derived structurally from
/// [ChatState.messages] — it is `true` whenever the most recent
/// message was authored by the user. Persistence of the assistant's
/// echo happens app-side (see `AppBloc`) so background-arrived
/// echoes always reach the right conversation regardless of which
/// surface is mounted.
/// {@endtemplate}
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  /// {@macro chat_bloc}
  ChatBloc({
    required String conversationId,
    required ConversationsRepository conversationsRepository,
    required ChatRepositoryProvider chatRepositoryProvider,
  })  : _conversationId = conversationId,
        _conversationsRepository = conversationsRepository,
        _chatRepositoryProvider = chatRepositoryProvider,
        super(const ChatState()) {
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatMessageSubmitted>(_onMessageSubmitted);
    on<ChatTransientErrorCleared>(_onTransientErrorCleared);

    _messagesSubscription = _conversationsRepository
        .watchMessages(_conversationId)
        .listen((messages) => add(ChatMessagesUpdated(messages)));
  }

  final String _conversationId;
  final ConversationsRepository _conversationsRepository;
  final ChatRepositoryProvider _chatRepositoryProvider;
  late final StreamSubscription<List<Message>> _messagesSubscription;

  void _onMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(messages: event.messages));
  }

  Future<void> _onMessageSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty || state.awaitingResponse) return;

    try {
      await _conversationsRepository.appendMessage(
        conversationId: _conversationId,
        role: MessageRole.user,
        text: trimmed,
      );
    } on Object {
      emit(
        state.copyWith(transientError: ChatTransientError.persistenceFailed),
      );
      return;
    }

    if (state.transientError != null) {
      emit(state.copyWith(clearTransientError: true));
    }

    final ChatRepository repository;
    try {
      repository = await _chatRepositoryProvider(_conversationId);
    } on ChatClientException {
      emit(
        state.copyWith(transientError: ChatTransientError.connectionFailed),
      );
      return;
    }

    try {
      await repository.send(trimmed);
    } on MessageTooLargeException {
      emit(state.copyWith(transientError: ChatTransientError.messageTooLarge));
    } on ChatClientException {
      emit(state.copyWith(transientError: ChatTransientError.sendFailed));
    }
  }

  void _onTransientErrorCleared(
    ChatTransientErrorCleared event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(clearTransientError: true));
  }

  @override
  Future<void> close() async {
    await _messagesSubscription.cancel();
    return super.close();
  }
}
