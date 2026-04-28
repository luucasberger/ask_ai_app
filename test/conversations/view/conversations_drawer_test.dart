import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:ask_ai_app/conversations/view/conversations_drawer.dart';
import 'package:ask_ai_app/conversations/widgets/conversation_tile.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockConversationsCubit extends MockCubit<ConversationsState>
    implements ConversationsCubit {}

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

  group(ConversationsDrawer, () {
    testWidgets('provides a $ConversationsCubit to its subtree', (
      tester,
    ) async {
      await tester.pumpApp(
        ConversationsDrawer(
          activeConversationId: null,
          onConversationTapped: (_) {},
          onNewChatTapped: () {},
        ),
      );
      await tester.pump();

      final view = tester.element(find.byType(ConversationsDrawerView));
      expect(view.read<ConversationsCubit>(), isA<ConversationsCubit>());
    });
  });

  group(ConversationsDrawerView, () {
    late _MockConversationsCubit cubit;

    setUp(() {
      cubit = _MockConversationsCubit();
    });

    Future<void> pumpView(
      WidgetTester tester, {
      String? activeConversationId,
      ValueChanged<String>? onConversationTapped,
      VoidCallback? onNewChatTapped,
    }) {
      return tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: ConversationsDrawerView(
            activeConversationId: activeConversationId,
            onConversationTapped: onConversationTapped ?? (_) {},
            onNewChatTapped: onNewChatTapped ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders the localized "new chat" CTA', (tester) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationsDrawerView(
                activeConversationId: null,
                onConversationTapped: (_) {},
                onNewChatTapped: () {},
              );
            },
          ),
        ),
      );

      expect(
        find.text(capturedContext.l10n.drawerNewChat),
        findsOneWidget,
      );
    });

    testWidgets('renders the localized section header', (tester) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationsDrawerView(
                activeConversationId: null,
                onConversationTapped: (_) {},
                onNewChatTapped: () {},
              );
            },
          ),
        ),
      );

      expect(
        find.text(capturedContext.l10n.drawerSectionConversations),
        findsOneWidget,
      );
    });

    testWidgets('renders the empty state when no conversations exist', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      late final BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationsDrawerView(
                activeConversationId: null,
                onConversationTapped: (_) {},
                onNewChatTapped: () {},
              );
            },
          ),
        ),
      );

      expect(
        find.text(capturedContext.l10n.drawerEmpty),
        findsOneWidget,
      );
      expect(find.byType(ConversationTile), findsNothing);
    });

    testWidgets('renders one $ConversationTile per conversation', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        ConversationsState(
          conversations: [
            buildConversation(id: 'a', title: 'Alpha'),
            buildConversation(id: 'b', title: 'Beta'),
          ],
        ),
      );

      await pumpView(tester);

      expect(find.byType(ConversationTile), findsNWidgets(2));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets(
      'marks the tile matching activeConversationId as selected',
      (tester) async {
        when(() => cubit.state).thenReturn(
          ConversationsState(
            conversations: [
              buildConversation(id: 'a', title: 'Alpha'),
              buildConversation(id: 'b', title: 'Beta'),
            ],
          ),
        );

        await pumpView(tester, activeConversationId: 'b');

        final selectedTile = tester.widget<ConversationTile>(
          find.byType(ConversationTile).at(1),
        );
        expect(selectedTile.selected, isTrue);
        final unselectedTile = tester.widget<ConversationTile>(
          find.byType(ConversationTile).first,
        );
        expect(unselectedTile.selected, isFalse);
      },
    );

    testWidgets('fires onConversationTapped with the tapped id', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        ConversationsState(
          conversations: [buildConversation(id: 'tap-me')],
        ),
      );

      String? tapped;
      await pumpView(tester, onConversationTapped: (id) => tapped = id);

      await tester.tap(find.byType(ConversationTile));
      await tester.pump();

      expect(tapped, 'tap-me');
    });

    testWidgets('fires onNewChatTapped when the CTA is tapped', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      var taps = 0;
      await pumpView(tester, onNewChatTapped: () => taps++);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
