part of 'conversations_cubit.dart';

/// {@template conversations_state}
/// State managed by [ConversationsCubit].
/// {@endtemplate}
final class ConversationsState extends Equatable {
  /// {@macro conversations_state}
  const ConversationsState({this.conversations = const []});

  /// All conversations ordered by [Conversation.updatedAt] descending,
  /// as observed from [ConversationsRepository.watchConversations].
  final List<Conversation> conversations;

  ConversationsState copyWith({List<Conversation>? conversations}) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
    );
  }

  @override
  List<Object?> get props => [conversations];
}
