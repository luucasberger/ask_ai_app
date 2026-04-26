import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:chat_repository/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ChatRepository? chatRepository,
  }) {
    return pumpWidget(
      RepositoryProvider<ChatRepository>.value(
        value: chatRepository ?? FakeChatRepository(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark,
          home: widget,
        ),
      ),
    );
  }
}
