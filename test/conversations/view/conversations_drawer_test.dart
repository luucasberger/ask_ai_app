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
          onRenameRequested: (_) {},
          onDeleteRequested: (_) {},
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
      ValueChanged<Conversation>? onRenameRequested,
      ValueChanged<Conversation>? onDeleteRequested,
    }) {
      return tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: ConversationsDrawerView(
            activeConversationId: activeConversationId,
            onConversationTapped: onConversationTapped ?? (_) {},
            onNewChatTapped: onNewChatTapped ?? () {},
            onRenameRequested: onRenameRequested ?? (_) {},
            onDeleteRequested: onDeleteRequested ?? (_) {},
          ),
        ),
      );
    }

    Future<BuildContext> pumpViewWithCapturedContext(
      WidgetTester tester, {
      String? activeConversationId,
      ValueChanged<String>? onConversationTapped,
      VoidCallback? onNewChatTapped,
      ValueChanged<Conversation>? onRenameRequested,
      ValueChanged<Conversation>? onDeleteRequested,
    }) async {
      late BuildContext capturedContext;
      await tester.pumpApp(
        BlocProvider<ConversationsCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationsDrawerView(
                activeConversationId: activeConversationId,
                onConversationTapped: onConversationTapped ?? (_) {},
                onNewChatTapped: onNewChatTapped ?? () {},
                onRenameRequested: onRenameRequested ?? (_) {},
                onDeleteRequested: onDeleteRequested ?? (_) {},
              );
            },
          ),
        ),
      );
      return capturedContext;
    }

    testWidgets('renders the localized "new chat" CTA', (tester) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      final context = await pumpViewWithCapturedContext(tester);

      expect(find.text(context.l10n.drawerNewChat), findsOneWidget);
    });

    testWidgets('renders the localized section header', (tester) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      final context = await pumpViewWithCapturedContext(tester);

      expect(
        find.text(context.l10n.drawerSectionConversations),
        findsOneWidget,
      );
    });

    testWidgets('renders the empty state when no conversations exist', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      final context = await pumpViewWithCapturedContext(tester);

      expect(find.text(context.l10n.drawerEmpty), findsOneWidget);
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

    testWidgets(
      'fires onRenameRequested when Rename is picked from the menu',
      (tester) async {
        final conversation = buildConversation(id: 'rename-me', title: 'Hi');
        when(() => cubit.state).thenReturn(
          ConversationsState(conversations: [conversation]),
        );

        Conversation? renamed;
        final context = await pumpViewWithCapturedContext(
          tester,
          onRenameRequested: (c) => renamed = c,
        );

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(context.l10n.conversationMenuRename),
        );
        await tester.pumpAndSettle();

        expect(renamed, conversation);
      },
    );

    testWidgets(
      'fires onDeleteRequested when Delete is picked from the menu',
      (tester) async {
        final conversation = buildConversation(id: 'delete-me');
        when(() => cubit.state).thenReturn(
          ConversationsState(conversations: [conversation]),
        );

        Conversation? deleted;
        final context = await pumpViewWithCapturedContext(
          tester,
          onDeleteRequested: (c) => deleted = c,
        );

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(context.l10n.conversationMenuDelete),
        );
        await tester.pumpAndSettle();

        expect(deleted, conversation);
      },
    );
  });
}
