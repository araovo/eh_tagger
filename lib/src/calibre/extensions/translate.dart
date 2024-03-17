import 'dart:core';

import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FieldFromTitle {
  String? publisher;
  String? title;
  String? author;
  String? magazineOrParody;
  List<String> additions;

  FieldFromTitle({
    this.publisher,
    this.title,
    this.author,
    this.magazineOrParody,
    required this.additions,
  });
}

extension TranslateExtension on CalibreMetadata {
  static String getName(List list, int i) {
    try {
      return list[i];
    } catch (_) {
      return '';
    }
  }

  static String getTableName(List<String> tagList) {
    String tableName = getName(tagList, 0);
    if (tableName == "group") {
      tableName = "groups";
    }
    return tableName;
  }

  static Future<String> findName(
      Database db, String comment, String raw) async {
    try {
      final List<Map> list = await db.rawQuery(comment);
      String str = list.first.values.first;
      if (str.contains(")")) {
        final exp = RegExp(r'\)(.*)');
        str = exp.firstMatch(str)!.group(1)!;
      }
      return str;
    } catch (_) {
      return raw;
    }
  }

  static Future<void> translate(Database? db, CalibreMetadata metadata) async {
    if (db == null) return;

    final tranTag = <String>[];
    final languages = <String>[];
    final groups = <String>[];
    final authors = <String>[];

    if (metadata.tags != null) {
      for (final tag in metadata.tags!) {
        final tagList = tag.split(":");
        final tableName = getTableName(tagList);
        final comment = "SELECT name from rows WHERE raw like '$tableName'";
        final nameSpace = await findName(db, comment, tableName);
        final raws = tagList[1].split(",");
        if (tagList.length == 1) {
          final comment =
              "SELECT name from reclass WHERE raw like '${tagList[0]}'";
          final newTag = await findName(db, comment, tagList[0]);
          tranTag.add(newTag);
          continue;
        }
        for (final raw in raws) {
          final comment = "SELECT name from $tableName WHERE raw like '$raw'";
          String newTag = await findName(db, comment, raw);
          if (tableName == "groups") {
            groups.add(newTag);
          } else if (tableName == "artist") {
            authors.add(newTag);
          } else {
            if (tableName == "language") {
              if (calibreLanguageMap.containsKey(newTag)) {
                languages.add(calibreLanguageMap[newTag]!);
              }
            }
            newTag = "$nameSpace:$newTag";
            tranTag.add(newTag);
          }
        }
      }
    }

    if (languages.isNotEmpty) {
      metadata.languages = List.from(languages);
    }
    String res = "";
    for (final group in groups) {
      if (groups.length <= 1) {
        metadata.publisher = group;
      }
      res = '$res$group&';
    }
    if (res.isNotEmpty) {
      metadata.publisher = res.trimRight().substring(0, res.length - 1);
    }
    metadata.authors = authors;
    metadata.tags = tranTag;
    final logs = Get.find<Logs>();
    logs.info('Translate metadata: ${metadata.toString()}');
  }

  static FieldFromTitle extractFieldFromTitle(String title) {
    final pattern = RegExp(
        r'^\s*(?:\(([^()]+)\))?\s*(?:\[([^[\]]+)\])?\s*([^[\]()]+)\s*(?:\(([^()]+)\))?\s*(?:\[([^[\]]+)\])?\s*(?:\[([^[\]]+)\])?\s*(?:\[([^[\]]+)\])?');

    final match = pattern.firstMatch(title);
    if (match != null) {
      final publisher = match.group(1);
      final author = match.group(2);
      final reTitle = match.group(3)?.trim();
      final magazineOrParody = match.group(4);
      final additionsWithNone = [
        match.group(5),
        match.group(6),
        match.group(7)
      ];
      final additionsWithoutNone =
          additionsWithNone.where((e) => e != null).map((e) => e!).toList();

      return FieldFromTitle(
        publisher: publisher,
        title: reTitle,
        author: author,
        magazineOrParody: magazineOrParody,
        additions: additionsWithoutNone,
      );
    } else {
      return FieldFromTitle(
        publisher: null,
        title: title,
        author: null,
        magazineOrParody: null,
        additions: [],
      );
    }
  }
}
