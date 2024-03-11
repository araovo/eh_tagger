import 'dart:convert';

import 'package:eh_tagger/src/calibre/extensions/translate.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';

class CalibreMetadata {
  String title;
  String eHentaiUrl = '';
  List<String>? authors;
  String? publisher;
  Map<String, dynamic>? identifiers;
  List<String>? tags;
  List<String>? languages;
  double? rating;

  CalibreMetadata({
    required this.title,
    required this.eHentaiUrl,
    this.authors,
    this.publisher,
    this.identifiers,
    this.tags,
    this.languages,
    this.rating,
  });

  @override
  String toString() {
    return '(title: $title, eHentaiUrl: $eHentaiUrl, authors: $authors, publisher: $publisher, identifiers: $identifiers, tags: $tags, languages: $languages, rating: $rating)';
  }

  factory CalibreMetadata.fromMap(Map<String, dynamic> map) {
    return CalibreMetadata(
      title: map['title'] as String,
      eHentaiUrl: map['eHentaiUrl'] as String,
      authors: (map['authors'] as String?)?.split(','),
      publisher: map['publisher'] as String?,
      identifiers: (map['identifiers'] as String?) != null
          ? jsonDecode(map['identifiers'] as String) as Map<String, dynamic>?
          : null,
      tags: (map['tags'] as String?)?.split(','),
      languages: (map['languages'] as String?)?.split(','),
      rating: map['rating'] as double?,
    );
  }

  factory CalibreMetadata.toMetadata(
    Map<String, dynamic> gmetadata, {
    bool useExHentai = false,
  }) {
    final title = gmetadata['title'] as String;
    final titleJpn = gmetadata['title_jpn'] as String;
    final tags =
        (gmetadata['tags'] as List).map((item) => item as String).toList();
    final rating = double.parse(gmetadata['rating'] as String);
    final category = gmetadata['category'] as String;
    final gid = gmetadata['gid'] as int;
    final token = gmetadata['token'] as String;

    bool isParody = false;
    final hasJpnTitle = titleJpn.isNotEmpty;

    final fieldFromTitle = TranslateExtension.extractFieldFromTitle(
        hasJpnTitle ? titleJpn : title);
    final processedTitle = fieldFromTitle.title;
    final publisher = fieldFromTitle.publisher;
    final author = fieldFromTitle.author ?? 'Unknown';
    final magazineOrParody = fieldFromTitle.magazineOrParody;
    final additions = fieldFromTitle.additions;

    final authors = [author];

    final metadata = CalibreMetadata(
      title: processedTitle ?? title,
      authors: authors,
      publisher: publisher ?? 'Unknown',
      identifiers: {
        'ehentai': '${gid}_${token}_${useExHentai ? 1 : 0}',
      },
      eHentaiUrl:
          'https://e${useExHentai ? 'x' : '-'}hentai.org/g/$gid/$token/',
    );

    final processedTags = <String>{};
    final languages = <String>{};
    for (final tag in tags) {
      processedTags.add(tag);
      if (RegExp(r'language').hasMatch(tag)) {
        final tag_ = tag.replaceAll('language:', '');
        if (tag_ != 'translated') {
          languages.add(tag_);
        }
      } else if (RegExp(r'parody').hasMatch(tag)) {
        isParody = true;
      }
    }
    processedTags.add('category:$category');

    if (!isParody && magazineOrParody != null) {
      processedTags.add('magazine:$magazineOrParody');
    }

    for (final addition
        in fieldFromTitle.additions + (hasJpnTitle ? additions : [])) {
      if (otherMap.containsKey(addition)) {
        processedTags.add('other:${otherMap[addition]}');
      } else if (languageMap.containsKey(addition)) {
        processedTags.add('language:${languageMap[addition]}');
        languages.add(languageMap[addition]!);
      } else {
        final dataPattern = RegExp(r'^\d{4}[-|年]\d{1,2}');
        if (dataPattern.hasMatch(addition)) {
          continue;
        }
        processedTags.add('translator:$addition');
      }
    }

    if (languages.isEmpty && hasJpnTitle) {
      languages.add('japanese');
    }

    metadata.tags = processedTags.toList();
    metadata.languages = languages.toList();
    metadata.rating = rating;

    return metadata;
  }
}
