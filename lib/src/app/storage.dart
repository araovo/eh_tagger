import 'dart:io';

import 'package:eh_tagger/src/app/constants.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppStorage {
  static late final String libraryPath;
  static late final String configPath;
  static late final String dbPath;
  static late final String transDbPath;
  static late final String booksPath;
  static late final String downloadPath;
  static late final String tempPath;

  static Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    libraryPath = join(documentsDirectory.path, packageName);
    configPath = join(libraryPath, configFileName);
    dbPath = join(libraryPath, dbFileName);
    transDbPath = join(libraryPath, transDbFileName);
    booksPath = join(libraryPath, booksDirectoryName);
    downloadPath = join(libraryPath, downloadDirName);
    tempPath = join(libraryPath, tempDirectoryName);
  }

  static bool transDbExists() {
    final transDbFile = File(join(libraryPath, transDbFileName));
    if (!transDbFile.existsSync()) {
      return false;
    }
    return true;
  }
}
