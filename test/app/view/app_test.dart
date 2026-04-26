import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/helpers.dart';

void main() {
  group(App, () {
    testWidgets('renders $ChatPage', (tester) async {
      await tester.pumpApp(App(chatRepository: FakeChatRepository()));
      await tester.pump();
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });
}
