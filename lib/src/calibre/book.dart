import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cross_file/cross_file.dart';
import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:eh_tagger/src/database/dao/books.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

class Book {
  int id;
  final selected = false.obs;
  final tapped = false.obs;
  String dir = '';
  String path = '';
  String coverPath = '';
  CalibreMetadata metadata;

  Book({
    required this.id,
    required this.dir,
    required this.path,
    required this.coverPath,
    required this.metadata,
  });

  factory Book.newBook({required String title, required String path}) {
    return Book(
      id: 0,
      dir: basename(path),
      path: path,
      coverPath: '',
      metadata: CalibreMetadata(title: title, eHentaiUrl: ''),
    );
  }
}

class BookHandler {
  static Future<List<Book>> addBooks({
    BuildContext? context,
    List<XFile>? xFiles,
    PlatformFile? platformFile,
    String? url,
    bool? deleteSourceBooks,
  }) async {
    final settings = Get.find<Settings>();
    final logs = Get.find<Logs>();
    // init settings
    final inputEHentaiUrl = settings.inputEHentaiUrl.value;
    late final bool delSourceBooks;
    if (deleteSourceBooks != null) {
      delSourceBooks = deleteSourceBooks;
    } else {
      delSourceBooks = settings.delSourceBooks.value;
    }
    final destDir = Directory(AppStorage.booksPath);
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    try {
      if (platformFile != null) {
        // after download from e-hentai
        final booksDao = BooksDaoImpl();
        final book = await addBook(platformFile);
        book.metadata.eHentaiUrl =
            url ?? ''; // it should be non-null, but just in case
        await booksDao.updateEHentaiUrl(
          id: book.id,
          title: book.metadata.title,
          eHentaiUrl: book.metadata.eHentaiUrl,
        );
        if (delSourceBooks) {
          final sourceFile = File(platformFile.path!);
          if (await sourceFile.exists()) {
            logs.info('Delete source file: ${sourceFile.path}');
            await sourceFile.delete();
          }
        }
        return [book];
      }
      FilePickerResult? result;
      late final List<PlatformFile> files;
      if (xFiles != null) {
        if (xFiles.isEmpty) return [];
        // convert XFile to PlatformFile
        final platformFiles = xFiles.map((file) async {
          final bytes = await file.readAsBytes();
          return PlatformFile(
            path: file.path,
            name: basename(file.path),
            size: bytes.length,
            bytes: bytes,
          );
        }).toList();
        files = await Future.wait(platformFiles);
      } else {
        result = await FilePicker.platform
            .pickFiles(allowMultiple: true, withData: true);
        if (result == null) return [];
        files = result.files;
      }

      final books = <Book>[];
      final booksDao = BooksDaoImpl();
      for (final file in files) {
        final book = await addBook(file);
        final shouldInputUrl = inputEHentaiUrl && context != null;
        if (shouldInputUrl && context.mounted) {
          final eHentaiUrl = await getEHentaiUrl(context, book.metadata.title);
          if (eHentaiUrl != null) {
            book.metadata.eHentaiUrl = eHentaiUrl;
            await booksDao.updateEHentaiUrl(
              id: book.id,
              title: book.metadata.title,
              eHentaiUrl: eHentaiUrl,
            );
          }
        }
        if (delSourceBooks) {
          final sourceFile = File(file.path!);
          if (await sourceFile.exists()) {
            logs.info('Delete source file: ${sourceFile.path}');
            await sourceFile.delete();
          }
        }
        books.add(book);
      }

      return books;
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  static Future<Book> addBook(PlatformFile file) async {
    final booksDao = BooksDaoImpl();
    final book = Book.newBook(
        title: basenameWithoutExtension(file.name),
        path: file.path!); // no .zip
    final id = await booksDao.insertBook(book);
    final destDir = Directory(join(AppStorage.booksPath, '$id')); // books/123
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }
    final dest = File(join(destDir.path, '$id.cbz')); // books/123/123.zip
    await dest.writeAsBytes(file.bytes!);
    String? coverPath = await exportFirstImage(destDir.path, dest.path);
    await booksDao.updateBookLocation(
        id: id,
        title: book.metadata.title,
        dir: destDir.path,
        path: dest.path,
        coverPath: coverPath ?? '');
    return book
      ..id = id
      ..dir = destDir.path
      ..path = dest.path
      ..coverPath = coverPath ?? '';
  }

  static Future<String?> getEHentaiUrl(
      BuildContext context, String bookTitle) async {
    final eHentaiUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.inputEHentaiUrl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(bookTitle),
              ),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'https://e-hentai.org/g/123456/abcdef1234/',
                ),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(textController.text);
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
    if (eHentaiUrl != null && eHentaiUrl.isNotEmpty) {
      return eHentaiUrl;
    }
    return null;
  }

  static Future<String?> exportFirstImage(String dir, String path) async {
    final inputStream = InputFileStream(path);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    final fileNames = archive
        .where((file) => file.isFile)
        .map((file) => file.name)
        .toList(growable: false);
    final firstImageFileName = fileNames.firstWhere(
        (file) => file.endsWith('.jpg') || file.endsWith('.png'),
        orElse: () => ''); // find first image
    if (firstImageFileName.isNotEmpty) {
      final image =
          archive.firstWhere((file) => file.name == firstImageFileName);
      final imageBytes = image.content as List<int>;
      // rename to cover.*
      final fileExtension = extension(firstImageFileName);
      final imageFile =
          File(join(dir, '$bookCoverFileNameWithNoExtension$fileExtension'));
      await imageFile.writeAsBytes(imageBytes);
      final logs = Get.find<Logs>();
      logs.info('Export first image: $firstImageFileName to ${imageFile.path}');
      return imageFile.path;
    }
    return null;
  }

  static Future<void> updateMetadata(
      Map<int, CalibreMetadata> metadataMap) async {
    final booksDao = BooksDaoImpl();
    for (final entry in metadataMap.entries) {
      await booksDao.updateMetadata(entry.key, entry.value);
    }
  }

  static Future<List<int>> deleteBooks(List<Book> books) async {
    final booksDao = BooksDaoImpl();
    final ids = <int>[];
    for (final book in books) {
      ids.add(
          await booksDao.deleteBook(id: book.id, title: book.metadata.title));
      final dir = Directory(book.dir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
    return ids;
  }
}
