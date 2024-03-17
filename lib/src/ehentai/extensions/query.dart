import 'dart:convert';

import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';
import 'package:eh_tagger/src/ehentai/ehentai.dart';
import 'package:eh_tagger/src/ehentai/extensions/calibre.dart';
import 'package:html_unescape/html_unescape.dart';

extension QueryExtension on EHentai {
  String? createQuery({
    String? title,
    bool useExHentai = false,
  }) {
    String reTitle = '';
    if (title != null) {
      final titleToken = getTitleTokens(title);
      if (titleToken.isNotEmpty) {
        reTitle = reTitle + buildTerm('title', titleToken);
      }
    }

    reTitle = reTitle.trim();
    if (reTitle.isEmpty) {
      return null;
    }

    if (reTitle.contains('Chinese') ||
        reTitle.contains('chinese') ||
        reTitle.contains('汉化') ||
        reTitle.contains('中国')) {
      reTitle = '$reTitle+l:chinese';
    }

    final qDict = {'f_cats': '0', 'f_search': reTitle};
    late final String url;
    if (useExHentai) {
      url = exHentaiSearchUrl + Uri(queryParameters: qDict).query;
    } else {
      url = eHentaiSearchUrl + Uri(queryParameters: qDict).query;
    }

    return url;
  }

  String? createQueryDetail({
    String? title,
    List<String>? authors,
    Map<String, dynamic>? identifiers,
    bool useExHentai = false,
  }) {
    String reTitle = '';

    if (title != null || authors != null) {
      final titleToken = getTitleTokens(title!);
      if (titleToken.isNotEmpty) {
        reTitle = reTitle + buildTerm('title', titleToken);
      }
      if (reTitle.length < 40) {
        if (authors != null) {
          if (!authors.contains('未知') || !authors.contains('Unknown')) {
            final authorToken = getAuthorTokens(authors, onlyFirstAuthor: true);
            if (authorToken.isNotEmpty) {
              reTitle = reTitle +
                  (reTitle.isNotEmpty ? ' ' : '') +
                  buildTerm('author', authorToken);
            }
          }
        }
      } else {
        final pattern = RegExp(
            r'(?<comments>.*?\[(?<author>(?:(?!汉化|漢化|CE家族|天鵝之戀)[^\[\]])*)\](?:\s*(?:\[[^()]+\]|\([^\[\]()]+\))\s*)*(?<Mtitle>[^\[\]()]+).*)');
        final match = pattern.firstMatch(reTitle);
        if (match != null) {
          final title = match.namedGroup('title');
          final comments = match.namedGroup('comments');
          final author = match.namedGroup('author');
          if (title != null) {
            if (title.length < 45) {
              reTitle = '$title ${author!}';
            } else {
              reTitle = title;
              final slen = (45 < reTitle.length ? 45 : reTitle.length);
              reTitle = reTitle.substring(0, slen);
            }
          }
          if (comments != null) {
            for (final key in languageMap.keys) {
              if (comments.contains(key)) {
                reTitle = '$reTitle $key';
              }
            }
          }
        }
      }
    }

    reTitle = reTitle.trim();
    if (reTitle.isEmpty) {
      return null;
    }
    reTitle = utf8.encode(reTitle).toString();

    final qDict = {'f_cats': '0', 'f_search': reTitle};
    late final String url;
    if (useExHentai) {
      url = exHentaiSearchUrl + Uri(queryParameters: qDict).query;
    } else {
      url = eHentaiSearchUrl + Uri(queryParameters: qDict).query;
    }

    return url;
  }

  bool _isSubsequence(String? s, String? t) {
    if (s == null || t == null) {
      return false;
    }
    int i = 0;
    int j = 0;
    while (i < s.length && j < t.length) {
      if (s[i] == t[j]) {
        i++;
      }
      j++;
    }
    return i == s.length;
  }

  Future<void> getAllDetails(
      List<List<String>> gidlist, String? title, int id) async {
    try {
      var gmetadatas = await getGmetadatas(gidlist);
      final newGmetadatas = <Map<String, dynamic>>[];
      final unescape = HtmlUnescape();
      for (final gmetadata in gmetadatas) {
        gmetadata['title_jpn'] = unescape.convert(gmetadata['title_jpn']);
        if (_isSubsequence(title, gmetadata['title_jpn'])) {
          newGmetadatas.add(gmetadata);
        }
      }
      if (newGmetadatas.isNotEmpty) {
        gmetadatas = newGmetadatas;
      }
      for (final gmetadata in gmetadatas) {
        try {
          final calibreMetadata =
              CalibreMetadata.toMetadata(gmetadata, useExHentai: useExHentai);
          metadataMap[id] = calibreMetadata;
        } catch (_) {
          rethrow;
        }
      }
    } catch (_) {
      rethrow;
    }
  }
}
