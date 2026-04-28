import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

const _databaseFileName = 'ask_ai.sqlite';

/// Opens the SQLite-backed [QueryExecutor] used by the conversations
/// client. Uses a [LazyDatabase] so the (async) path lookup defers
/// until drift first needs the connection.
QueryExecutor openConversationsDatabase() {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final supportDir = await getApplicationSupportDirectory();
    final file = File(p.join(supportDir.path, _databaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
