import 'package:ask_ai_app/app/app.dart';
import 'package:ask_ai_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
