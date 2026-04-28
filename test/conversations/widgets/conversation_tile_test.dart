import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/conversations/widgets/conversation_tile.dart';
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

  group(ConversationTile, () {
    testWidgets('renders the conversation title', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: ConversationTile(
            conversation: buildConversation(title: 'Lunch plans'),
            selected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Lunch plans'), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        Scaffold(
          body: ConversationTile(
            conversation: buildConversation(),
            selected: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(ConversationTile));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('marks the underlying $ListTile as selected', (tester) async {
      await tester.pumpApp(
        Scaffold(
          body: ConversationTile(
            conversation: buildConversation(),
            selected: true,
            onTap: () {},
          ),
        ),
      );

      final tile = tester.widget<ListTile>(find.byType(ListTile));
      expect(tile.selected, isTrue);
    });
  });
}
