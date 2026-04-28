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
  });
}
