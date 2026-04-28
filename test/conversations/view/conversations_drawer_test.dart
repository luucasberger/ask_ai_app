import 'package:ask_ai_app/conversations/cubit/conversations_cubit.dart';
import 'package:ask_ai_app/conversations/view/conversations_drawer.dart';
import 'package:ask_ai_app/conversations/widgets/conversation_tile.dart';
import 'package:ask_ai_app/conversations/widgets/folder_tile.dart';
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
    String? folderId,
  }) {
    return Conversation(
      id: id,
      title: title,
      folderId: folderId,
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
          onMoveRequested: (_, __) {},
          onMoveToNewFolderRequested: (_) {},
          onNewFolderRequested: () {},
          onFolderRenameRequested: (_) {},
          onFolderDeleteRequested: (_) {},
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
      void Function(Conversation, String?)? onMoveRequested,
      ValueChanged<Conversation>? onMoveToNewFolderRequested,
      VoidCallback? onNewFolderRequested,
      ValueChanged<Folder>? onFolderRenameRequested,
      ValueChanged<Folder>? onFolderDeleteRequested,
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
            onMoveRequested: onMoveRequested ?? (_, __) {},
            onMoveToNewFolderRequested: onMoveToNewFolderRequested ?? (_) {},
            onNewFolderRequested: onNewFolderRequested ?? () {},
            onFolderRenameRequested: onFolderRenameRequested ?? (_) {},
            onFolderDeleteRequested: onFolderDeleteRequested ?? (_) {},
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
      void Function(Conversation, String?)? onMoveRequested,
      ValueChanged<Conversation>? onMoveToNewFolderRequested,
      VoidCallback? onNewFolderRequested,
      ValueChanged<Folder>? onFolderRenameRequested,
      ValueChanged<Folder>? onFolderDeleteRequested,
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
                onMoveRequested: onMoveRequested ?? (_, __) {},
                onMoveToNewFolderRequested:
                    onMoveToNewFolderRequested ?? (_) {},
                onNewFolderRequested: onNewFolderRequested ?? () {},
                onFolderRenameRequested: onFolderRenameRequested ?? (_) {},
                onFolderDeleteRequested: onFolderDeleteRequested ?? (_) {},
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

    testWidgets('renders the localized Folders section header with +', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      final context = await pumpViewWithCapturedContext(tester);

      expect(find.text(context.l10n.drawerSectionFolders), findsOneWidget);
      expect(
        find.byTooltip(context.l10n.drawerNewFolderTooltip),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders the empty state when no folders and no conversations exist',
      (tester) async {
        when(() => cubit.state).thenReturn(ConversationsState());

        final context = await pumpViewWithCapturedContext(tester);

        expect(find.text(context.l10n.drawerEmpty), findsOneWidget);
        expect(find.byType(FolderTile), findsNothing);
        expect(find.byType(ConversationTile), findsNothing);
      },
    );

    testWidgets(
      'renders one $ConversationTile per uncategorized conversation, '
      'no Uncategorized header when there are no folders',
      (tester) async {
        when(() => cubit.state).thenReturn(
          ConversationsState(
            conversations: [
              buildConversation(id: 'a', title: 'Alpha'),
              buildConversation(id: 'b', title: 'Beta'),
            ],
          ),
        );

        final context = await pumpViewWithCapturedContext(tester);

        expect(find.byType(ConversationTile), findsNWidgets(2));
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsOneWidget);
        expect(
          find.text(context.l10n.drawerSectionUncategorized),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders folder tiles, the Uncategorized header, and loose '
      'conversations when both are present',
      (tester) async {
        when(() => cubit.state).thenReturn(
          ConversationsState(
            folders: [
              buildFolder(id: 'f-1', name: 'Books'),
            ],
            conversations: [
              buildConversation(
                id: 'c-1',
                title: 'In folder',
                folderId: 'f-1',
              ),
              buildConversation(id: 'c-2', title: 'Loose'),
            ],
          ),
        );

        final context = await pumpViewWithCapturedContext(tester);

        expect(find.byType(FolderTile), findsOneWidget);
        expect(find.text('Books'), findsOneWidget);
        expect(
          find.text(context.l10n.drawerSectionUncategorized),
          findsOneWidget,
        );
        expect(find.text('Loose'), findsOneWidget);
      },
    );

    testWidgets(
      'omits the Uncategorized header when folders exist but no loose '
      'conversations',
      (tester) async {
        when(() => cubit.state).thenReturn(
          ConversationsState(
            folders: [buildFolder(id: 'f-1', name: 'Books')],
            conversations: [
              buildConversation(
                id: 'c-1',
                title: 'In folder',
                folderId: 'f-1',
              ),
            ],
          ),
        );

        final context = await pumpViewWithCapturedContext(tester);

        expect(find.byType(FolderTile), findsOneWidget);
        expect(
          find.text(context.l10n.drawerSectionUncategorized),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders nested ConversationTiles inside an expanded folder',
      (tester) async {
        when(() => cubit.state).thenReturn(
          ConversationsState(
            folders: [buildFolder(id: 'f-1', name: 'Books')],
            conversations: [
              buildConversation(
                id: 'c-1',
                title: 'Nested chat',
                folderId: 'f-1',
              ),
            ],
          ),
        );

        await pumpView(tester);

        // Collapsed by default.
        expect(find.text('Nested chat'), findsNothing);

        await tester.tap(find.text('Books'));
        await tester.pumpAndSettle();

        expect(find.text('Nested chat'), findsOneWidget);
      },
    );

    testWidgets(
      'marks the active conversation tile as selected (uncategorized)',
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

        final tiles = tester
            .widgetList<ConversationTile>(find.byType(ConversationTile))
            .toList();
        expect(tiles, hasLength(2));
        expect(
          tiles.firstWhere((t) => t.conversation.id == 'b').selected,
          isTrue,
        );
        expect(
          tiles.firstWhere((t) => t.conversation.id == 'a').selected,
          isFalse,
        );
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

    testWidgets('fires onNewFolderRequested when the + action is tapped', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(ConversationsState());

      var taps = 0;
      final context = await pumpViewWithCapturedContext(
        tester,
        onNewFolderRequested: () => taps++,
      );

      await tester.tap(
        find.byTooltip(context.l10n.drawerNewFolderTooltip),
      );
      await tester.pump();

      expect(taps, equals(1));
    });

    testWidgets(
      'fires onRenameRequested when Rename is picked from a conversation menu',
      (tester) async {
        final conversation = buildConversation(id: 'rename-me');
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
        await tester.tap(find.text(context.l10n.conversationMenuRename));
        await tester.pumpAndSettle();

        expect(renamed, conversation);
      },
    );

    testWidgets(
      'fires onDeleteRequested when Delete is picked from a conversation menu',
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
        await tester.tap(find.text(context.l10n.conversationMenuDelete));
        await tester.pumpAndSettle();

        expect(deleted, equals(conversation));
      },
    );

    testWidgets(
      'fires onMoveRequested with the picked folder id from the submenu',
      (tester) async {
        final conversation = buildConversation(id: 'move-me');
        final folder = buildFolder(id: 'f-1', name: 'Books');
        when(() => cubit.state).thenReturn(
          ConversationsState(
            folders: [folder],
            conversations: [conversation],
          ),
        );

        Conversation? movedConversation;
        Object? movedTo = 'unset';
        final context = await pumpViewWithCapturedContext(
          tester,
          onMoveRequested: (c, id) {
            movedConversation = c;
            movedTo = id;
          },
        );

        // The conversation here is uncategorized — long-press it.
        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(context.l10n.conversationMenuMoveToFolder),
        );
        await tester.pumpAndSettle();
        // The folder name 'Books' appears both as the FolderTile header
        // and as an entry in the move submenu — disambiguate by widget
        // ancestor.
        await tester.tap(find.widgetWithText(MenuItemButton, 'Books'));
        await tester.pumpAndSettle();

        expect(movedConversation, equals(conversation));
        expect(movedTo, equals('f-1'));
      },
    );

    testWidgets(
      'fires onMoveToNewFolderRequested when "New folder…" is picked',
      (tester) async {
        final conversation = buildConversation(id: 'move-me');
        when(() => cubit.state).thenReturn(
          ConversationsState(conversations: [conversation]),
        );

        Conversation? requested;
        final context = await pumpViewWithCapturedContext(
          tester,
          onMoveToNewFolderRequested: (c) => requested = c,
        );

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(context.l10n.conversationMenuMoveToFolder),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(context.l10n.conversationMenuMoveToNewFolder),
        );
        await tester.pumpAndSettle();

        expect(requested, equals(conversation));
      },
    );

    group('nested ConversationTile inside a folder', () {
      const folderId = 'f-1';
      const conversationId = 'c-1';
      final folder = Folder(
        id: folderId,
        name: 'Books',
        createdAt: DateTime.utc(2026, 4, 27),
      );
      final nested = Conversation(
        id: conversationId,
        title: 'Nested',
        folderId: folderId,
        createdAt: DateTime.utc(2026, 4, 27),
        updatedAt: DateTime.utc(2026, 4, 27),
      );

      void seedNested() {
        when(() => cubit.state).thenReturn(
          ConversationsState(folders: [folder], conversations: [nested]),
        );
      }

      Future<void> expandFolder(WidgetTester tester) async {
        await tester.tap(find.text('Books'));
        await tester.pumpAndSettle();
      }

      testWidgets('reflects activeConversationId via selected styling', (
        tester,
      ) async {
        seedNested();
        await pumpView(tester, activeConversationId: conversationId);
        await expandFolder(tester);

        final tile = tester.widget<ConversationTile>(
          find.byType(ConversationTile),
        );
        expect(tile.selected, isTrue);
      });

      testWidgets('forwards onTap with the conversation id', (tester) async {
        seedNested();
        String? tappedId;
        await pumpView(tester, onConversationTapped: (id) => tappedId = id);
        await expandFolder(tester);

        await tester.tap(find.byType(ConversationTile));
        await tester.pump();

        expect(tappedId, conversationId);
      });

      testWidgets('forwards onRenameRequested via the menu', (tester) async {
        seedNested();
        Conversation? renamed;
        final context = await pumpViewWithCapturedContext(
          tester,
          onRenameRequested: (c) => renamed = c,
        );
        await expandFolder(tester);

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text(context.l10n.conversationMenuRename));
        await tester.pumpAndSettle();

        expect(renamed, equals(nested));
      });

      testWidgets('forwards onDeleteRequested via the menu', (tester) async {
        seedNested();
        Conversation? deleted;
        final context = await pumpViewWithCapturedContext(
          tester,
          onDeleteRequested: (c) => deleted = c,
        );
        await expandFolder(tester);

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text(context.l10n.conversationMenuDelete));
        await tester.pumpAndSettle();

        expect(deleted, equals(nested));
      });

      testWidgets(
        'forwards onMoveRequested with null when "Uncategorized" is picked',
        (tester) async {
          seedNested();
          Conversation? moved;
          Object? movedTo = 'unset';
          final context = await pumpViewWithCapturedContext(
            tester,
            onMoveRequested: (c, id) {
              moved = c;
              movedTo = id;
            },
          );
          await expandFolder(tester);

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToUncategorized),
          );
          await tester.pumpAndSettle();

          expect(moved, equals(nested));
          expect(movedTo, isNull);
        },
      );

      testWidgets(
        'forwards onMoveToNewFolderRequested via the submenu',
        (tester) async {
          seedNested();
          Conversation? requested;
          final context = await pumpViewWithCapturedContext(
            tester,
            onMoveToNewFolderRequested: (c) => requested = c,
          );
          await expandFolder(tester);

          await tester.longPress(find.byType(ConversationTile));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToFolder),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(context.l10n.conversationMenuMoveToNewFolder),
          );
          await tester.pumpAndSettle();

          expect(requested, equals(nested));
        },
      );
    });

    testWidgets(
      'fires onFolderRenameRequested when Rename is picked from the menu',
      (tester) async {
        final folder = buildFolder(id: 'f-1', name: 'Books');
        when(() => cubit.state)
            .thenReturn(ConversationsState(folders: [folder]));

        Folder? renamed;
        final context = await pumpViewWithCapturedContext(
          tester,
          onFolderRenameRequested: (f) => renamed = f,
        );

        await tester.longPress(find.byType(FolderTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text(context.l10n.folderMenuRename));
        await tester.pumpAndSettle();

        expect(renamed, equals(folder));
      },
    );

    testWidgets(
      'fires onFolderDeleteRequested when Delete is picked from the menu',
      (tester) async {
        final folder = buildFolder(id: 'f-1', name: 'Books');
        when(() => cubit.state)
            .thenReturn(ConversationsState(folders: [folder]));

        Folder? deleted;
        final context = await pumpViewWithCapturedContext(
          tester,
          onFolderDeleteRequested: (f) => deleted = f,
        );

        await tester.longPress(find.byType(FolderTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text(context.l10n.folderMenuDelete));
        await tester.pumpAndSettle();

        expect(deleted, equals(folder));
      },
    );
  });
}
