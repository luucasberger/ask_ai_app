import 'dart:async';

import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  Conversation buildConversation({
    String id = 'c0',
    String title = 'A conversation',
  }) {
    return Conversation(
      id: id,
      title: title,
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );
  }

  Folder buildFolder({
    String id = 'f0',
    String name = 'A folder',
  }) {
    return Folder(id: id, name: name, createdAt: DateTime.utc(2026, 4, 27));
  }

  group(ConversationsCubit, () {
    late MockConversationsRepository conversationsRepository;
    late StreamController<List<Conversation>> conversationsController;
    late StreamController<List<Folder>> foldersController;

    setUp(() {
      conversationsRepository = MockConversationsRepository();
      conversationsController =
          StreamController<List<Conversation>>.broadcast();
      foldersController = StreamController<List<Folder>>.broadcast();
      when(conversationsRepository.watchConversations).thenAnswer(
        (_) => conversationsController.stream,
      );
      when(conversationsRepository.watchFolders).thenAnswer(
        (_) => foldersController.stream,
      );
    });

    tearDown(() async {
      await conversationsController.close();
      await foldersController.close();
    });

    ConversationsCubit buildCubit() => ConversationsCubit(
          conversationsRepository: conversationsRepository,
        );

    test('initial state has no conversations and no folders', () {
      expect(buildCubit().state, ConversationsState());
    });

    test('subscribes to watchConversations and watchFolders', () {
      buildCubit();
      verify(conversationsRepository.watchConversations).called(1);
      verify(conversationsRepository.watchFolders).called(1);
    });

    blocTest<ConversationsCubit, ConversationsState>(
      'emits each conversations list pushed by the repository stream',
      build: buildCubit,
      act: (_) {
        conversationsController
          ..add([buildConversation(id: 'a')])
          ..add([buildConversation(id: 'a'), buildConversation(id: 'b')]);
      },
      expect: () => [
        ConversationsState(conversations: [buildConversation(id: 'a')]),
        ConversationsState(
          conversations: [
            buildConversation(id: 'a'),
            buildConversation(id: 'b'),
          ],
        ),
      ],
    );

    blocTest<ConversationsCubit, ConversationsState>(
      'emits each folders list pushed by the repository stream',
      build: buildCubit,
      act: (_) {
        foldersController
          ..add([buildFolder(id: 'f1')])
          ..add([buildFolder(id: 'f1'), buildFolder(id: 'f2')]);
      },
      expect: () => [
        ConversationsState(folders: [buildFolder(id: 'f1')]),
        ConversationsState(
          folders: [buildFolder(id: 'f1'), buildFolder(id: 'f2')],
        ),
      ],
    );

    test('close cancels both subscriptions', () async {
      final cubit = buildCubit();
      await cubit.close();
      expect(conversationsController.hasListener, isFalse);
      expect(foldersController.hasListener, isFalse);
    });

    group('rename', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'forwards a trimmed title to the repository',
        setUp: () {
          when(
            () => conversationsRepository.renameConversation(
              id: any(named: 'id'),
              title: any(named: 'title'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildCubit,
        act: (cubit) => cubit.rename(id: 'c-1', title: '  New title  '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.renameConversation(
              id: 'c-1',
              title: 'New title',
            ),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'is a no-op when title is blank',
        build: buildCubit,
        act: (cubit) => cubit.rename(id: 'c-1', title: '   '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.renameConversation(
              id: any(named: 'id'),
              title: any(named: 'title'),
            ),
          );
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces renameFailed when the repository throws',
        setUp: () {
          when(
            () => conversationsRepository.renameConversation(
              id: any(named: 'id'),
              title: any(named: 'title'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.rename(id: 'c-1', title: 'New title'),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.renameFailed,
          ),
        ],
      );
    });

    group('moveConversation', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'forwards id and folderId to the repository',
        setUp: () {
          when(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversation(id: 'c-1', folderId: 'f-1'),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.moveConversation(
              id: 'c-1',
              folderId: 'f-1',
            ),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'forwards a null folderId to mean "Uncategorized"',
        setUp: () {
          when(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversation(id: 'c-1', folderId: null),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.moveConversation(id: 'c-1'),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces moveFailed when the repository throws',
        setUp: () {
          when(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversation(id: 'c-1', folderId: 'f-1'),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.moveFailed,
          ),
        ],
      );
    });

    group('createFolder', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'forwards a trimmed name to the repository',
        setUp: () {
          when(
            () => conversationsRepository.createFolder(any()),
          ).thenAnswer((_) async => buildFolder(id: 'f-1', name: 'Books'));
        },
        build: buildCubit,
        act: (cubit) => cubit.createFolder('  Books  '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.createFolder('Books'),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'is a no-op when name is blank',
        build: buildCubit,
        act: (cubit) => cubit.createFolder('   '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.createFolder(any()),
          );
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces folderCreateFailed when the repository throws',
        setUp: () {
          when(
            () => conversationsRepository.createFolder(any()),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.createFolder('Books'),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.folderCreateFailed,
          ),
        ],
      );
    });

    group('moveConversationToNewFolder', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'creates the folder, then moves the conversation into it',
        setUp: () {
          when(
            () => conversationsRepository.createFolder(any()),
          ).thenAnswer((_) async => buildFolder(id: 'f-1', name: 'Books'));
          when(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversationToNewFolder(
          conversationId: 'c-1',
          name: '  Books  ',
        ),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.createFolder('Books'),
          ).called(1);
          verify(
            () => conversationsRepository.moveConversation(
              id: 'c-1',
              folderId: 'f-1',
            ),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'is a no-op when name is blank',
        build: buildCubit,
        act: (cubit) => cubit.moveConversationToNewFolder(
          conversationId: 'c-1',
          name: '   ',
        ),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verifyNever(() => conversationsRepository.createFolder(any()));
          verifyNever(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          );
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces folderCreateFailed and skips the move when create throws',
        setUp: () {
          when(
            () => conversationsRepository.createFolder(any()),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversationToNewFolder(
          conversationId: 'c-1',
          name: 'Books',
        ),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.folderCreateFailed,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          );
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces moveFailed when the move throws after a successful create',
        setUp: () {
          when(
            () => conversationsRepository.createFolder(any()),
          ).thenAnswer((_) async => buildFolder(id: 'f-1', name: 'Books'));
          when(
            () => conversationsRepository.moveConversation(
              id: any(named: 'id'),
              folderId: any(named: 'folderId'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.moveConversationToNewFolder(
          conversationId: 'c-1',
          name: 'Books',
        ),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.moveFailed,
          ),
        ],
      );
    });

    group('renameFolder', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'forwards a trimmed name to the repository',
        setUp: () {
          when(
            () => conversationsRepository.renameFolder(
              id: any(named: 'id'),
              name: any(named: 'name'),
            ),
          ).thenAnswer((_) async {});
        },
        build: buildCubit,
        act: (cubit) => cubit.renameFolder(id: 'f-1', name: '  Reading  '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verify(
            () => conversationsRepository.renameFolder(
              id: 'f-1',
              name: 'Reading',
            ),
          ).called(1);
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'is a no-op when name is blank',
        build: buildCubit,
        act: (cubit) => cubit.renameFolder(id: 'f-1', name: '   '),
        expect: () => <ConversationsState>[],
        verify: (_) {
          verifyNever(
            () => conversationsRepository.renameFolder(
              id: any(named: 'id'),
              name: any(named: 'name'),
            ),
          );
        },
      );

      blocTest<ConversationsCubit, ConversationsState>(
        'surfaces folderRenameFailed when the repository throws',
        setUp: () {
          when(
            () => conversationsRepository.renameFolder(
              id: any(named: 'id'),
              name: any(named: 'name'),
            ),
          ).thenThrow(StorageException('boom'));
        },
        build: buildCubit,
        act: (cubit) => cubit.renameFolder(id: 'f-1', name: 'Reading'),
        expect: () => [
          ConversationsState(
            transientError: ConversationsTransientError.folderRenameFailed,
          ),
        ],
      );
    });

    group('clearTransientError', () {
      blocTest<ConversationsCubit, ConversationsState>(
        'clears the transient error',
        seed: () => ConversationsState(
          transientError: ConversationsTransientError.renameFailed,
        ),
        build: buildCubit,
        act: (cubit) => cubit.clearTransientError(),
        expect: () => [ConversationsState()],
      );
    });
  });
}
