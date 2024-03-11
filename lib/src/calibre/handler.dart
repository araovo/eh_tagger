import 'dart:convert';
import 'dart:io';

import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

class CalibreHandler {
  static Future<bool> saveBooks(List<Book> books) async {
    try {
      final settings = Get.find<Settings>();
      final logs = Get.find<Logs>();
      final calibredb = File(settings.calibredbPath.value);
      final metadataDb = File(settings.metadataDbPath.value);
      if (!await calibredb.exists()) {
        throw Exception('calibredb not found');
      }
      if (!await metadataDb.exists()) {
        throw Exception('Metadata database not found');
      }
      final metadataDir = metadataDb.parent;
      final bookFileList = books.map((e) => e.path).toList();
      String libraryPath = metadataDir.path;

      final tempLibraryDir =
          Directory(join(AppStorage.tempPath, tempCalibreLibraryDirName));
      if (settings.netDriveOptimization.value) {
        if (!await tempLibraryDir.exists()) {
          await tempLibraryDir.create(recursive: true);
        } else {
          await tempLibraryDir.delete(recursive: true);
          await tempLibraryDir.create(recursive: true);
        }
        await metadataDb.copy(join(tempLibraryDir.path, 'metadata.db'));
        logs.info('Copy metadata.db to temp library');
        libraryPath = tempLibraryDir.path;
      }
      final arguments = [
        '-d',
        'add',
        ...bookFileList,
        '--library-path',
        libraryPath,
      ];
      logs.info('calibredb: ${calibredb.path} ${arguments.join(' ')}');
      final process = await Process.start(calibredb.path, arguments);
      process.stdout.transform(utf8.decoder).listen((data) {
        logs.info('calibredb: ${data.trim()}');
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        logs.error('calibredb: ${data.trim()}');
      });
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('calibredb add failed');
      }
      if (settings.netDriveOptimization.value) {
        // copy all files and directories from tempLibraryDir to libraryDir
        logs.info('Copy temp library to real library');
        await copyDirectory(tempLibraryDir, metadataDir);
        await tempLibraryDir.delete(recursive: true);
        logs.info('Delete temp library');
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> copyDirectory(
      Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory =
            Directory(join(destination.path, basename(entity.path)));
        await newDirectory.create();
        await copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(join(destination.path, basename(entity.path)));
      }
    }
  }
}
