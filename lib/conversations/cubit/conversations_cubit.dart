import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:equatable/equatable.dart';

part 'conversations_state.dart';

/// {@template conversations_cubit}
/// Owns the drawer's view of the user's conversation list.
///
/// Subscribes to [ConversationsRepository.watchConversations] in its
/// constructor and re-emits whenever the underlying drift query
/// emits — re-renders are reactive, no explicit refresh action is
/// needed.
///
/// Also owns the rename action — delete is handled app-side by
/// `AppBloc` because it can mutate the active conversation id.
/// {@endtemplate}
class ConversationsCubit extends Cubit<ConversationsState> {
  /// {@macro conversations_cubit}
  ConversationsCubit({
    required ConversationsRepository conversationsRepository,
  })  : _conversationsRepository = conversationsRepository,
        super(const ConversationsState()) {
    _subscription = _conversationsRepository.watchConversations().listen(
          (conversations) => emit(
            state.copyWith(conversations: conversations),
          ),
        );
  }

  final ConversationsRepository _conversationsRepository;
  late final StreamSubscription<List<Conversation>> _subscription;

  /// Renames the conversation identified by [id] to [title].
  ///
  /// Trims [title]; no-ops on a blank result. Storage failures surface
  /// as [ConversationsTransientError.renameFailed].
  Future<void> rename({required String id, required String title}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      await _conversationsRepository.renameConversation(
        id: id,
        title: trimmed,
      );
    } on Object {
      emit(
        state.copyWith(
          transientError: ConversationsTransientError.renameFailed,
        ),
      );
    }
  }

  /// Clears [ConversationsState.transientError] after the view has
  /// surfaced it (e.g. via snackbar).
  void clearTransientError() {
    emit(state.copyWith(clearTransientError: true));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
