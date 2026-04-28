import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:equatable/equatable.dart';

part 'conversations_state.dart';

/// {@template conversations_cubit}
/// Owns the drawer's view of the user's conversation list and folders.
///
/// Subscribes to [ConversationsRepository.watchConversations] and
/// [ConversationsRepository.watchFolders] in its constructor and
/// re-emits whenever the underlying drift queries emit — re-renders
/// are reactive, no explicit refresh action is needed.
///
/// Owns rename, folder CRUD, and move actions. Conversation **delete**
/// and folder **delete** are handled app-side because they can mutate
/// the active conversation id and need to dispose chat repositories.
/// {@endtemplate}
class ConversationsCubit extends Cubit<ConversationsState> {
  /// {@macro conversations_cubit}
  ConversationsCubit({
    required ConversationsRepository conversationsRepository,
  })  : _conversationsRepository = conversationsRepository,
        super(const ConversationsState()) {
    _conversationsSubscription =
        _conversationsRepository.watchConversations().listen(
              (conversations) => emit(
                state.copyWith(conversations: conversations),
              ),
            );
    _foldersSubscription = _conversationsRepository.watchFolders().listen(
          (folders) => emit(state.copyWith(folders: folders)),
        );
  }

  final ConversationsRepository _conversationsRepository;
  late final StreamSubscription<List<Conversation>> _conversationsSubscription;
  late final StreamSubscription<List<Folder>> _foldersSubscription;

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

  /// Moves the conversation identified by [id] into [folderId], or to
  /// "Uncategorized" when [folderId] is `null`.
  ///
  /// Storage failures surface as [ConversationsTransientError.moveFailed].
  Future<void> moveConversation({
    required String id,
    required String? folderId,
  }) async {
    try {
      await _conversationsRepository.moveConversation(
        id: id,
        folderId: folderId,
      );
    } on Object {
      emit(
        state.copyWith(transientError: ConversationsTransientError.moveFailed),
      );
    }
  }

  /// Creates a new folder named [name].
  ///
  /// Trims [name]; no-ops on a blank result. Storage failures surface
  /// as [ConversationsTransientError.folderCreateFailed].
  Future<void> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _conversationsRepository.createFolder(trimmed);
    } on Object {
      emit(
        state.copyWith(
          transientError: ConversationsTransientError.folderCreateFailed,
        ),
      );
    }
  }

  /// Creates a new folder named [name] and immediately moves the
  /// conversation identified by [conversationId] into it.
  ///
  /// Trims [name]; no-ops on a blank result. If folder creation fails,
  /// surfaces [ConversationsTransientError.folderCreateFailed] and the
  /// move is skipped. If only the subsequent move fails, surfaces
  /// [ConversationsTransientError.moveFailed] (the folder remains).
  Future<void> moveConversationToNewFolder({
    required String conversationId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final Folder folder;
    try {
      folder = await _conversationsRepository.createFolder(trimmed);
    } on Object {
      emit(
        state.copyWith(
          transientError: ConversationsTransientError.folderCreateFailed,
        ),
      );
      return;
    }
    try {
      await _conversationsRepository.moveConversation(
        id: conversationId,
        folderId: folder.id,
      );
    } on Object {
      emit(
        state.copyWith(transientError: ConversationsTransientError.moveFailed),
      );
    }
  }

  /// Renames the folder identified by [id] to [name].
  ///
  /// Trims [name]; no-ops on a blank result. Storage failures surface
  /// as [ConversationsTransientError.folderRenameFailed].
  Future<void> renameFolder({
    required String id,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _conversationsRepository.renameFolder(id: id, name: trimmed);
    } on Object {
      emit(
        state.copyWith(
          transientError: ConversationsTransientError.folderRenameFailed,
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
    await _conversationsSubscription.cancel();
    await _foldersSubscription.cancel();
    return super.close();
  }
}
