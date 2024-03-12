import 'dart:convert';

import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:eh_tagger/src/database/database.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class BooksDao {
  Future<List<Book>> queryBooks();

  Future<int> insertBook(Book book);

  Future<void> updateBookLocation({
    required int id,
    required String title,
    required String dir,
    required String path,
    required coverPath,
  });

  Future<void> updateEHentaiUrl({
    required int id,
    required String title,
    required String eHentaiUrl,
  });

  Future<void> updateBook(Book book);

  Future<void> updateMetadata(int id, CalibreMetadata metadata);

  Future<int> deleteBook({required int id, required String title});
}

class BooksDaoImpl implements BooksDao {
  static final BooksDaoImpl _instance = BooksDaoImpl._internal();
  late final Database _db;
  final _logs = Get.find<Logs>();

  factory BooksDaoImpl() {
    return _instance;
  }

  BooksDaoImpl._internal() {
    _db = AppDatabase().db;
  }

  @override
  Future<List<Book>> queryBooks() async {
    var maps = <Map<String, dynamic>>[];
    try {
      maps = await _db.query('books');
    } catch (e) {
      _logs.error('Query books: $e');
      return [];
    }
    _logs.info('Query books: ${maps.length}');
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

  @override
  Future<int> insertBook(Book book) async {
    final result = await _db.insert(
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
    _logs.info('Insert book: ${book.metadata.title} from ${book.path}');
    return result;
  }

  @override
  Future<void> updateBookLocation({
    required int id,
    required String title,
    required String dir,
    required String path,
    required coverPath,
  }) async {
    await _db.update(
      'books',
      {
        'dir': dir,
        'path': path,
        'coverPath': coverPath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _logs.info('Update book location: $title');
  }

  @override
  Future<void> updateEHentaiUrl({
    required int id,
    required String title,
    required String eHentaiUrl,
  }) async {
    await _db.update(
      'books',
      {
        'eHentaiUrl': eHentaiUrl,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _logs.info('Update eHentaiUrl: $title');
  }

  @override
  Future<void> updateBook(Book book) async {
    await _db.update(
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
    _logs.info('Update book: ${book.metadata.title}');
  }

  @override
  Future<void> updateMetadata(int id, CalibreMetadata metadata) async {
    await _db.update(
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
    _logs.info('Update metadata: ${metadata.title}');
  }

  @override
  Future<int> deleteBook({required int id, required String title}) async {
    await _db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    _logs.info('Delete book: $title');
    return id;
  }
}
