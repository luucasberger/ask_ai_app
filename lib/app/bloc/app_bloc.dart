import 'dart:async';

import 'package:ask_ai_app/app/registry/chat_repository_registry.dart';
import 'package:bloc/bloc.dart';
import 'package:chat_client/chat_client.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:equatable/equatable.dart';

part 'app_event.dart';
part 'app_state.dart';

/// Storage key for the conversation id the user had active when the
/// app last shut down.
const lastActiveConversationKey = 'last_active_conversation_id';

/// Maximum number of characters used when auto-titling a new
/// conversation from the user's first message.
const _autoTitleMaxLength = 40;

/// {@template app_bloc}
/// Owns conversation-routing concerns that span the whole app:
/// the active conversation id, persistence of incoming assistant
/// messages, the in-progress typewriter id, and the orchestration
/// of the very first send in a brand-new conversation.
///
/// Per-conversation [ChatRepository]s live inside the
/// [ChatRepositoryRegistry] (a peer dependency in the widget tree),
/// not the bloc. The bloc subscribes to
/// [ChatRepositoryRegistry.echoes] and forwards each event as an
/// [AppEchoReceived].
/// {@endtemplate}
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  AppBloc({
    required ConversationsRepository conversationsRepository,
    required ChatRepositoryRegistry chatRepositoryRegistry,
  })  : _conversationsRepository = conversationsRepository,
        _chatRepositoryRegistry = chatRepositoryRegistry,
        super(const AppState()) {
    on<AppStarted>(_onStarted);
    on<AppConversationActivated>(_onConversationActivated);
    on<AppNewConversationRequested>(_onNewConversationRequested);
    on<AppConversationDeleted>(_onConversationDeleted);
    on<AppFirstMessageSubmitted>(_onFirstMessageSubmitted);
    on<AppEchoReceived>(_onEchoReceived);
    on<AppStreamingCompleted>(_onStreamingCompleted);
    on<AppTransientErrorCleared>(_onTransientErrorCleared);

    _echoSubscription = chatRepositoryRegistry.echoes.listen(
      (event) => add(
        AppEchoReceived(
          conversationId: event.conversationId,
          text: event.text,
        ),
      ),
    );
  }

  final ConversationsRepository _conversationsRepository;
  final ChatRepositoryRegistry _chatRepositoryRegistry;
  late final StreamSubscription<EchoEvent> _echoSubscription;

  Future<void> _onStarted(AppStarted event, Emitter<AppState> emit) async {
    final id = await _conversationsRepository.readMetadata(
      lastActiveConversationKey,
    );
    if (id == null) return;
    emit(state.copyWith(activeConversationId: id));
  }

  Future<void> _onConversationActivated(
    AppConversationActivated event,
    Emitter<AppState> emit,
  ) async {
    emit(
      state.copyWith(
        activeConversationId: event.conversationId,
        clearStreamingMessageId: true,
      ),
    );
    await _conversationsRepository.writeMetadata(
      key: lastActiveConversationKey,
      value: event.conversationId,
    );
  }

  Future<void> _onNewConversationRequested(
    AppNewConversationRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(
      state.copyWith(
        clearActiveConversationId: true,
        clearStreamingMessageId: true,
      ),
    );
    await _conversationsRepository.writeMetadata(
      key: lastActiveConversationKey,
    );
  }

  Future<void> _onConversationDeleted(
    AppConversationDeleted event,
    Emitter<AppState> emit,
  ) async {
    final id = event.conversationId;
    try {
      await _conversationsRepository.deleteConversation(id);
    } on Object {
      emit(state.copyWith(transientError: AppTransientError.deleteFailed));
      return;
    }
    await _chatRepositoryRegistry.dispose(id);
    if (state.activeConversationId == id) {
      emit(
        state.copyWith(
          clearActiveConversationId: true,
          clearStreamingMessageId: true,
        ),
      );
      await _conversationsRepository.writeMetadata(
        key: lastActiveConversationKey,
      );
    }
  }

  Future<void> _onFirstMessageSubmitted(
    AppFirstMessageSubmitted event,
    Emitter<AppState> emit,
  ) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;

    final Conversation conversation;
    try {
      conversation = await _conversationsRepository.createConversation(
        title: autoTitle(trimmed),
      );
      await _conversationsRepository.appendMessage(
        conversationId: conversation.id,
        role: MessageRole.user,
        text: trimmed,
      );
    } on Object {
      emit(
        state.copyWith(transientError: AppTransientError.persistenceFailed),
      );
      return;
    }

    emit(
      state.copyWith(
        activeConversationId: conversation.id,
        clearStreamingMessageId: true,
        clearTransientError: true,
      ),
    );
    await _conversationsRepository.writeMetadata(
      key: lastActiveConversationKey,
      value: conversation.id,
    );

    final ChatRepository repository;
    try {
      repository = await _chatRepositoryRegistry.obtain(conversation.id);
    } on ChatClientException {
      emit(state.copyWith(transientError: AppTransientError.connectionFailed));
      return;
    }

    try {
      await repository.send(trimmed);
    } on MessageTooLargeException {
      emit(state.copyWith(transientError: AppTransientError.messageTooLarge));
    } on ChatClientException {
      emit(state.copyWith(transientError: AppTransientError.sendFailed));
    }
  }

  Future<void> _onEchoReceived(
    AppEchoReceived event,
    Emitter<AppState> emit,
  ) async {
    try {
      final message = await _conversationsRepository.appendMessage(
        conversationId: event.conversationId,
        role: MessageRole.assistant,
        text: event.text,
      );
      if (state.activeConversationId == event.conversationId) {
        emit(state.copyWith(streamingMessageId: message.id));
      }
    } on Object {
      emit(
        state.copyWith(transientError: AppTransientError.persistenceFailed),
      );
    }
  }

  void _onStreamingCompleted(
    AppStreamingCompleted event,
    Emitter<AppState> emit,
  ) {
    if (state.streamingMessageId != event.messageId) return;
    emit(state.copyWith(clearStreamingMessageId: true));
  }

  void _onTransientErrorCleared(
    AppTransientErrorCleared event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(clearTransientError: true));
  }

  /// Builds the auto-generated title for a new conversation, derived
  /// from the user's first message. Trims whitespace and truncates to
  /// [_autoTitleMaxLength] characters with an ellipsis suffix when
  /// longer.
  static String autoTitle(String firstMessage) {
    final trimmed = firstMessage.trim();
    if (trimmed.length <= _autoTitleMaxLength) return trimmed;
    return '${trimmed.substring(0, _autoTitleMaxLength)}…';
  }

  @override
  Future<void> close() async {
    await _echoSubscription.cancel();
    return super.close();
  }
}
