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
      ),
    );
  }

  static Future<void> create(Database db, int version) async {
    await db.execute(createBooksTable);
  }
}
