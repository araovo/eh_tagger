import 'package:eh_tagger/src/app/app.dart';
import 'package:eh_tagger/src/app/books.dart';
import 'package:eh_tagger/src/app/config.dart';
import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/database/database.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logs = Logs();
  Get.put(logs);

  late final Settings settings;
  bool storageInitialized = false;

  try {
    await AppStorage.init();
    logs.info('Library path: ${AppStorage.libraryPath}');
    logs.info('Config path: ${AppStorage.configPath}');
    logs.info('Database path: ${AppStorage.dbPath}');
    logs.info('Books path: ${AppStorage.booksPath}');
    logs.info('Download path: ${AppStorage.downloadPath}');
    logs.info('Temp path: ${AppStorage.tempPath}');
    storageInitialized = true;
  } catch (e, st) {
    logs.error('Failed to initialize storage: $e');
    logs.error(st.toString());
    final defaultConfig = Config.defaultConfig();
    settings = Settings.fromConfig(defaultConfig);
  }
  try {
    settings = Settings.loadConfig();
  } catch (e, st) {
    logs.error('Failed to load config: $e');
    logs.error(st.toString());
    final defaultConfig = Config.defaultConfig();
    settings = Settings.fromConfig(defaultConfig);
  }
  Get.put(settings);

  if (storageInitialized) {
    await AppDatabase.init();
    settings.setDbInitialized(true);
    logs.info('Database initialized');
    final booksControler = BooksController();
    await booksControler.queryBooks();
    Get.put(booksControler);
    final downloader = Downloader(settings: settings, logs: logs);
    await downloader.queryTasks();
    Get.put(downloader);
  } else {
    logs.error('Database not initialized');
    settings.setDbInitialized(false);
  }

  await windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const App());
}
