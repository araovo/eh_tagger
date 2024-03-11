import 'dart:io';

import 'package:eh_tagger/src/calibre/book.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class OpfHandler {
  static String? getLanguage(List<String>? languages) {
    if (languages == null) {
      return null;
    }
    if (languages.contains('中文')) {
      return 'zh';
    }
    return 'jpn';
  }

  static void saveOpf(Book book) {
    final metadata = book.metadata;
    final builder = XmlBuilder();
    const uuid = Uuid();
    builder.processing('xml', 'version=\'1.0\' encoding=\'utf-8\'');
    builder.element('package', attributes: {
      'xmlns': 'http://www.idpf.org/2007/opf',
      'unique-identifier': 'uuid_id',
      'version': '2.0'
    }, nest: () {
      builder.element('metadata', attributes: {
        'xmlns:dc': 'http://purl.org/dc/elements/1.1/',
        'xmlns:opf': 'http://www.idpf.org/2007/opf'
      }, nest: () {
        builder.element('dc:identifier',
            attributes: {'opf:scheme': 'calibre', 'id': 'calibre_id'},
            nest: book.id.toString());
        builder.element('dc:identifier',
            attributes: {'opf:scheme': 'uuid', 'id': 'uuid_id'},
            nest: uuid.v4());
        builder.element('dc:title', nest: metadata.title);
        if (metadata.authors != null) {
          final authorString = metadata.authors!.join(' &amp; ');
          for (final author in metadata.authors ?? []) {
            builder.element(
              'dc:creator',
              attributes: {'opf:file-as': authorString, 'opf:role': 'aut'},
              nest: author,
            );
          }
        }
        builder.element('dc:contributor',
            attributes: {'opf:file-as': 'calibre', 'opf:role': 'bkp'},
            nest: 'calibre (7.5.1) [https://calibre-ebook.com]');
        builder.element('dc:date', nest: '0101-01-01T00:00:00+00:00');
        builder.element('dc:publisher', nest: metadata.publisher);
        builder.element(
          'dc:identifier',
          attributes: {'opf:scheme': 'EHENTAI'},
          nest: metadata.identifiers?['ehentai'],
        );
        builder.element('dc:language', nest: getLanguage(metadata.languages));
        for (final tag in metadata.tags ?? []) {
          builder.element('dc:subject', nest: tag);
        }
        if (metadata.rating != null) {
          builder.element('meta', attributes: {
            'name': 'calibre:rating',
            'content': (metadata.rating! * 2).toString()
          });
        }
        final now = DateTime.now().toUtc();
        final newNow = DateTime(
            now.year, now.month, now.day, now.hour, now.minute, now.second);
        final formatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss+00:00");
        final timeString = formatter.format(newNow);
        builder.element('meta', attributes: {
          'name': 'calibre:timestamp',
          'content': timeString,
        });
        builder.element('meta', attributes: {
          'name': 'calibre:title_sort',
          'content': metadata.title
        });
      });
      builder.element('guide', nest: () {
        if (book.coverPath.isNotEmpty) {
          final coverFileName = basename(book.coverPath);
          if (coverFileName.isNotEmpty && !coverFileName.endsWith('.gif')) {
            builder.element('reference', attributes: {
              'type': 'cover',
              'title': '封面',
              'href': basename(book.coverPath)
            });
          }
        }
      });
    });
    final opfPath = join(book.dir, '${book.id}.opf');
    final opfFile = File(opfPath);
    opfFile
        .writeAsStringSync(builder.buildDocument().toXmlString(pretty: true));
  }
}
