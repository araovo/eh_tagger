import 'dart:convert';

import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  late final Database db;
  final logs = Get.find<Logs>();

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
        version: 1,
        onCreate: (db, version) async {
          await AppDatabase.create(db, version);
        },
      ),
    );
    final logs = Get.find<Logs>();
    logs.info('Database initialized');
  }

  static Future<void> create(Database db, int version) async {
    await db.execute(createDatabaseComment);
  }

  Future<List<Book>> queryBooks() async {
    var maps = <Map<String, dynamic>>[];
    try {
      maps = await db.query('books');
    } catch (e) {
      logs.error('Query books: $e');
      return [];
    }
    logs.info('Query books: ${maps.length}');
    return List.generate(maps.length, (i) {
      return Book(
        id: maps[i]['id'] as int,
        dir: maps[i]['dir'] as String,
        path: maps[i]['path'] as String,
        coverPath: maps[i]['coverPath'] as String,
        metadata: CalibreMetadata.fromMap(maps[i]),
      );
    }).reversed.toList();
  }

  Future<int> insertBook(Book book) async {
    final result = await db.insert(
      'books',
      {
        'dir': book.dir,
        'path': book.path,
        'coverPath': book.coverPath,
        'title': book.metadata.title,
        'authors': book.metadata.authors?.join(','),
        'publisher': book.metadata.publisher,
        'identifiers': jsonEncode(book.metadata.identifiers),
        'tags': book.metadata.tags?.join(','),
        'languages': book.metadata.languages?.join(','),
        'rating': book.metadata.rating,
        'eHentaiUrl': book.metadata.eHentaiUrl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    logs.info('Insert book: ${book.metadata.title} from ${book.path}');
    return result;
  }

  Future<void> updateBookLocation({
    required int id,
    required String title,
    required String dir,
    required String path,
    required coverPath,
  }) async {
    await db.update(
      'books',
      {
        'dir': dir,
        'path': path,
        'coverPath': coverPath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    logs.info('Update book location: $title');
  }

  Future<void> updateEHentaiUrl(
      {required int id,
      required String title,
      required String eHentaiUrl}) async {
    await db.update(
      'books',
      {
        'eHentaiUrl': eHentaiUrl,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    logs.info('Update eHentaiUrl: $title');
  }

  Future<void> updateBook(Book book) async {
    await db.update(
      'books',
      {
        'dir': book.dir,
        'path': book.path,
        'coverPath': book.coverPath,
        'title': book.metadata.title,
        'authors': book.metadata.authors?.join(','),
        'publisher': book.metadata.publisher,
        'identifiers': jsonEncode(book.metadata.identifiers),
        'tags': book.metadata.tags?.join(','),
        'languages': book.metadata.languages?.join(','),
        'rating': book.metadata.rating,
        'eHentaiUrl': book.metadata.eHentaiUrl,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
    logs.info('Update book: ${book.metadata.title}');
  }

  Future<void> updateMetadata(int id, CalibreMetadata metadata) async {
    await db.update(
      'books',
      {
        'title': metadata.title,
        'authors': metadata.authors?.join(','),
        'publisher': metadata.publisher,
        'identifiers': jsonEncode(metadata.identifiers),
        'tags': metadata.tags?.join(','),
        'languages': metadata.languages?.join(','),
        'rating': metadata.rating,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    logs.info('Update metadata: ${metadata.title}');
  }

  Future<int> deleteBook({required int id, required String title}) async {
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    logs.info('Delete book: $title');
    return id;
  }
}
