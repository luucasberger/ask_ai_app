import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/conversation_tile.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpTile(
    WidgetTester tester, {
    Conversation? conversation,
    bool selected = false,
    VoidCallback? onTap,
    VoidCallback? onRenameSelected,
    VoidCallback? onDeleteSelected,
  }) {
    return tester.pumpApp(
      Scaffold(
        body: ConversationTile(
          conversation: conversation ?? buildConversation(),
          selected: selected,
          onTap: onTap ?? () {},
          onRenameSelected: onRenameSelected ?? () {},
          onDeleteSelected: onDeleteSelected ?? () {},
        ),
      ),
    );
  }

  group(ConversationTile, () {
    testWidgets('renders the conversation title', (tester) async {
      await pumpTile(
        tester,
        conversation: buildConversation(title: 'Lunch plans'),
      );

      expect(find.text('Lunch plans'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await pumpTile(tester, onTap: () => taps++);

      await tester.tap(find.byType(ConversationTile));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('marks the underlying $ListTile as selected', (tester) async {
      await pumpTile(tester, selected: true);

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.selected, isTrue);
    });

    testWidgets(
      'long-press opens a menu with localized Rename and Delete entries',
      (tester) async {
        late final BuildContext capturedContext;
        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return ConversationTile(
                  conversation: buildConversation(),
                  selected: false,
                  onTap: () {},
                  onRenameSelected: () {},
                  onDeleteSelected: () {},
                );
              },
            ),
          ),
        );

        await tester.longPress(find.byType(ConversationTile));
        await tester.pumpAndSettle();

        expect(
          find.text(capturedContext.l10n.conversationMenuRename),
          findsOneWidget,
        );
        expect(
          find.text(capturedContext.l10n.conversationMenuDelete),
          findsOneWidget,
        );
      },
    );

    testWidgets('fires onRenameSelected when the Rename entry is tapped', (
      tester,
    ) async {
      var renames = 0;
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationTile(
                conversation: buildConversation(),
                selected: false,
                onTap: () {},
                onRenameSelected: () => renames++,
                onDeleteSelected: () {},
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(capturedContext.l10n.conversationMenuRename),
      );
      await tester.pumpAndSettle();

      expect(renames, 1);
    });

    testWidgets('fires onDeleteSelected when the Delete entry is tapped', (
      tester,
    ) async {
      var deletes = 0;
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationTile(
                conversation: buildConversation(),
                selected: false,
                onTap: () {},
                onRenameSelected: () {},
                onDeleteSelected: () => deletes++,
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(capturedContext.l10n.conversationMenuDelete),
      );
      await tester.pumpAndSettle();

      expect(deletes, 1);
    });

    testWidgets('long-pressing again while the menu is open closes it', (
      tester,
    ) async {
      late final BuildContext capturedContext;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return ConversationTile(
                conversation: buildConversation(),
                selected: false,
                onTap: () {},
                onRenameSelected: () {},
                onDeleteSelected: () {},
              );
            },
          ),
        ),
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      expect(
        find.text(capturedContext.l10n.conversationMenuRename),
        findsOneWidget,
      );

      await tester.longPress(find.byType(ConversationTile));
      await tester.pumpAndSettle();
      expect(
        find.text(capturedContext.l10n.conversationMenuRename),
        findsNothing,
      );
    });
  });
}
