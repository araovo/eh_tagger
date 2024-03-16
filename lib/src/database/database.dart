import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  late final Database db;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  static Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _instance.db = await databaseFactoryFfi.openDatabase(
      AppStorage.dbPath,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onCreate: (db, version) async {
          await AppDatabase.create(db, version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await AppDatabase.upgrade(db, oldVersion, newVersion);
        },
      ),
    );
  }

  static Future<void> create(Database db, int version) async {
    await db.execute(createBooksTable);
    await db.execute(createDownloadTasksTable);
  }

  static Future<void> upgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion == newVersion) return;
    switch (oldVersion) {
      case 1:
        await db.execute(createDownloadTasksTable);
        break;
      default:
        break;
    }
  }
}
