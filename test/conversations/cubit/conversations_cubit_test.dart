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

  group(ConversationsCubit, () {
    late MockConversationsRepository conversationsRepository;
    late StreamController<List<Conversation>> controller;

    setUp(() {
      conversationsRepository = MockConversationsRepository();
      controller = StreamController<List<Conversation>>.broadcast();
      when(conversationsRepository.watchConversations).thenAnswer(
        (_) => controller.stream,
      );
    });

    tearDown(() async {
      await controller.close();
    });

    ConversationsCubit buildCubit() => ConversationsCubit(
          conversationsRepository: conversationsRepository,
        );

    test('initial state has no conversations', () {
      expect(buildCubit().state, ConversationsState());
    });

    test('subscribes to watchConversations', () {
      buildCubit();
      verify(conversationsRepository.watchConversations).called(1);
    });

    blocTest<ConversationsCubit, ConversationsState>(
      'emits each list pushed by the repository stream',
      build: buildCubit,
      act: (_) {
        controller
          ..add([buildConversation(id: 'a')])
          ..add([
            buildConversation(id: 'a'),
            buildConversation(id: 'b'),
          ]);
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

    test('close cancels the subscription', () async {
      final cubit = buildCubit();
      await cubit.close();
      expect(controller.hasListener, isFalse);
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
