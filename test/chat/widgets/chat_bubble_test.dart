import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/chat/widgets/chat_bubble.dart';
import 'package:ask_ai_app/chat/widgets/typewriter_text.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  Message buildMessage({
    String id = 'm0',
    MessageRole role = MessageRole.user,
    String text = 'hi',
  }) {
    return Message(
      id: id,
      conversationId: 'c0',
      role: role,
      text: text,
      sentAt: DateTime.utc(2026, 4, 27),
    );
  }

  group(ChatBubble, () {
    testWidgets('renders user message right-aligned with userBubble color', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            final colors = context.appColors;
            return ChatBubble(
              message: buildMessage(id: '1', text: 'hello'),
              streaming: false,
              onStreamingCompleted: () {},
              key: ValueKey('user-bubble-${colors.userBubble.toARGB32()}'),
            );
          },
        ),
      );

      expect(find.text('hello'), findsOneWidget);
      final align = tester.widget<Align>(
        find.ancestor(of: find.text('hello'), matching: find.byType(Align)),
      );
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets(
      'renders assistant message left-aligned with assistantBubble color',
      (tester) async {
        await tester.pumpApp(
          ChatBubble(
            message: buildMessage(
              id: '2',
              role: MessageRole.assistant,
              text: 'hi back',
            ),
            streaming: false,
            onStreamingCompleted: () {},
          ),
        );

        expect(find.text('hi back'), findsOneWidget);
        final align = tester.widget<Align>(
          find.ancestor(
            of: find.text('hi back'),
            matching: find.byType(Align),
          ),
        );
        expect(align.alignment, Alignment.centerLeft);
      },
    );

    testWidgets('renders $TypewriterText when streaming', (tester) async {
      var completedCount = 0;
      await tester.pumpApp(
        ChatBubble(
          message: buildMessage(
            id: '3',
            role: MessageRole.assistant,
            text: 'streaming',
          ),
          streaming: true,
          onStreamingCompleted: () => completedCount++,
        ),
      );

      expect(find.byType(TypewriterText), findsOneWidget);

      // Reveal characters until completion fires.
      for (var i = 0; i < 'streaming'.length + 1; i++) {
        await tester.pump(Duration(milliseconds: 30));
      }
      expect(completedCount, 1);
    });

    testWidgets('renders plain Text when not streaming', (tester) async {
      await tester.pumpApp(
        ChatBubble(
          message: buildMessage(
            id: '4',
            role: MessageRole.assistant,
            text: 'static',
          ),
          streaming: false,
          onStreamingCompleted: () {},
        ),
      );

      expect(find.byType(TypewriterText), findsNothing);
      expect(find.text('static'), findsOneWidget);
    });
  });
}
