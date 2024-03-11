import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TranslationDatabase {
  // do not use singleton
  late final Database db;

  Future<void> init(String transDbArchivePath) async {
    await databaseFactoryFfi.deleteDatabase(AppStorage.transDbPath);
    final logs = Get.find<Logs>();
    db = await databaseFactoryFfi.openDatabase(
      AppStorage.transDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await TranslationDatabase.create(
              db, version, transDbArchivePath, logs);
        },
      ),
    );
    logs.info('Translation Database updated');
    await db.close();
  }

  static Future<void> create(
      Database db, int version, String transDbArchivePath, Logs logs) async {
    final mdNames = [
      'artist',
      'character',
      'cosplayer',
      'female',
      'group',
      'language',
      'male',
      'mixed',
      'other',
      'parody',
      'reclass',
      'rows'
    ];
    final mdPath = join(transDbArchivePath, 'database');
    for (final md in mdNames) {
      final tableName = md == 'group' ? 'groups' : md;
      final mdName = '$md.md';
      final list = readMd(join(mdPath, mdName));
      if (tableName == 'reclass') {
        await createTable(db, 'category', logs);
        list.add(magazineList);
        await addDatabase(db, list, 'category', logs);
      } else if (tableName == 'rows') {
        await createTable(db, 'rows', logs);
        list.addAll(missingRowsList);
        await addDatabase(db, list, 'rows', logs);
      } else {
        await createTable(db, tableName, logs);
        await addDatabase(db, list, tableName, logs);
      }
    }
    // remove temp files
    await Directory(transDbArchivePath).delete(recursive: true);
  }

  static Future<void> createTable(
      Database db, String tableName, Logs logs) async {
    await db.execute("DROP TABLE IF EXISTS $tableName");
    await db.execute(
        "CREATE TABLE $tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, raw TEXT NOT NULL, name TEXT NOT NULL, intro TEXT, links TEXT, UNIQUE (raw ASC))");
    logs.info('Created table: $tableName');
  }

  static bool check(String str) {
    final exp = RegExp(r"[A-Za-z]");
    return exp.hasMatch(str);
  }

  static Future<void> addDatabase(
      Database db, List<List<String>> list, String tableName, Logs logs) async {
    for (final value in list) {
      String raw = getValue(value, 0).trim();
      String name = getValue(value, 1).trim();
      if (name.contains(' \\')) {
        name = name.replaceAll(' \\', '');
      }
      String intro = getValue(value, 2).trim();
      String links = getValue(value, 3).trim();
      try {
        await db.rawInsert(
            "INSERT INTO $tableName(raw, name, intro, links) VALUES(?, ?, ?, ?)",
            [raw, name, intro, links]);
      } catch (e) {
        logs.error('Failed to add $name to $tableName: $e');
      }
    }
    logs.info('Added ${list.length} rows to $tableName');
  }

  static List<List<String>> readMd(String path) {
    final List<List<String>> list = [];
    final List<String> lines = File(path)
        .readAsLinesSync(encoding: utf8)
        .map((line) => line.trim())
        .toList();
    bool flag = false;
    for (var line in lines) {
      if (line.contains('原始标签')) {
        flag = true;
      }
      if (flag) {
        line = line.replaceAll('<br>', '');
        line = line.replaceAll('\'', '\'\'');
        List<String> tagList = line.split('|');
        tagList =
            tagList.where((tag) => tag.isNotEmpty && tag != '  ').toList();
        if (tagList.length >= 2) {
          if (check(tagList[0])) {
            list.add(tagList);
          }
        }
      }
    }
    return list;
  }

  static String getValue(List<String> value, int i) {
    try {
      return value[i];
    } catch (_) {
      return '';
    }
  }
}

class TranslationDatabaseUpdater {
  final logs = Get.find<Logs>();
  final dio = Dio();

  TranslationDatabaseUpdater(Settings settings) {
    dio.options.connectTimeout = httpTimeout;
    dio.options.receiveTimeout = httpTimeout;
    if (settings.useProxy.value && settings.proxyLink.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) {
            return 'PROXY ${settings.proxyLink}';
          };
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }
  }

  bool shouldUpdate(String currentVersion, String latestVersion) {
    if (currentVersion.isEmpty) {
      return true;
    }
    final cv = Version.parse(currentVersion.replaceAll('v', ''));
    final lv = Version.parse(latestVersion.replaceAll('v', ''));
    return cv < lv;
  }

  Future<String> getLatestVersion() async {
    try {
      final response = await dio.get(transDbApiUrl);
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Failed to get latest translation database version');
      }
      final data = response.data;
      final version = data['tag_name'];
      if (version == null) {
        throw Exception('Failed to get latest translation database version');
      }
      logs.info('Latest translation database version: $version');
      return version as String;
    } catch (_) {
      rethrow;
    }
  }

  Future<String> downloadArchive(String version) async {
    try {
      final response = await dio.get(
        '$transDbArchiveUrl/$version.zip',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Failed to download translation database archive');
      }
      final archive = response.data;
      final tempDir = Directory(AppStorage.tempPath);
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final tempFile = File(join(tempDir.path, '$version.zip'));
      await tempFile.writeAsBytes(archive);
      logs.info('Downloaded translation database archive: ${tempFile.path}');
      return tempFile.path;
    } catch (_) {
      rethrow;
    }
  }

  Future<String> unzipArchive(String path) async {
    try {
      final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
      final archiveName = basenameWithoutExtension(path);
      final tempDir = Directory(AppStorage.tempPath);
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      /*
      // remove old files
      await tempDir.list().forEach((file) async {
        if (file is File) {
          logs.info('Deleting old file: ${file.path}');
          await file.delete();
        }
      });
      so dangerous
       */
      await extractArchiveToDiskAsync(archive, tempDir.path);
      // delete temp file
      await File(path).delete();
      logs.info('Deleted translation database archive: $path');
      // archiveName: v*.zip
      final transDbArchiveName = archiveName.replaceFirst('v', 'Database-');
      // transDbArchiveRename: Database
      final archiveDir = Directory(join(tempDir.path, transDbArchiveName));
      // rename Database-* to Database
      final transDbArchiveDir =
          Directory(join(tempDir.path, transDbArchiveRename));
      if (await transDbArchiveDir.exists()) {
        // delete old Database
        await transDbArchiveDir.delete(recursive: true);
      }
      await archiveDir.rename(transDbArchiveDir.path);
      logs.info(
          'Unzipped translation database archive: ${transDbArchiveDir.path}');
      return transDbArchiveDir.path;
    } catch (e) {
      throw Exception('Failed to unzip translation database archive: $e');
    }
  }
}
