import 'package:app_ui/app_ui.dart';
import 'package:ask_ai_app/app/bloc/app_bloc.dart';
import 'package:ask_ai_app/l10n/l10n.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:conversations_repository/conversations_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks.dart';

class _StubAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ConversationsRepository? conversationsRepository,
    AppBloc? appBloc,
  }) {
    final repo = conversationsRepository ?? FakeConversationsRepository();
    final bloc = appBloc ?? (_StubAppBloc()..stub(const AppState()));
    return pumpWidget(
      RepositoryProvider<ConversationsRepository>.value(
        value: repo,
        child: BlocProvider<AppBloc>.value(
          value: bloc,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark,
            home: widget,
          ),
        ),
      ),
    );
  }
}

extension on _StubAppBloc {
  void stub(AppState state) {
    whenListen(
      this,
      const Stream<AppState>.empty(),
      initialState: state,
    );
  }
}
