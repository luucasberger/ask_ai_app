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
/// {@endtemplate}
class ConversationsCubit extends Cubit<ConversationsState> {
  /// {@macro conversations_cubit}
  ConversationsCubit({
    required ConversationsRepository conversationsRepository,
  }) : _conversationsRepository = conversationsRepository,
       super(const ConversationsState()) {
    _subscription = _conversationsRepository.watchConversations().listen(
      (conversations) => emit(
        state.copyWith(conversations: conversations),
      ),
    );
  }

  final ConversationsRepository _conversationsRepository;
  late final StreamSubscription<List<Conversation>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
