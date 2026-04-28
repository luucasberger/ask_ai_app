import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group(App, () {
    testWidgets('renders $ChatPage', (tester) async {
      await tester.pumpWidget(
        App(
          conversationsRepository: FakeConversationsRepository(),
          chatRepositoryFactory: (_) => FakeChatRepository(),
        ),
      );
      await tester.pump();

      expect(find.byType(ChatPage), findsOneWidget);
    });

    testWidgets('tap on the chrome unfocuses the primary focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        App(
          conversationsRepository: FakeConversationsRepository(),
          chatRepositoryFactory: (_) => FakeChatRepository(),
        ),
      );
      await tester.pump();

      final gestureDetector = find.descendant(
        of: find.byType(App),
        matching: find.byType(GestureDetector),
      );
      await tester.tap(gestureDetector.first, warnIfMissed: false);
      await tester.pump();
    });
  });
}
