import 'package:eh_tagger/src/ehentai/ehentai.dart';

extension CalibreExtension on EHentai {
  List<String> getTitleTokens(
    String title, {
    bool stripJoiners = true,
    bool stripSubtitle = false,
  }) {
    List<String> results = [];

    if (title.isNotEmpty) {
      if (stripSubtitle) {
        RegExp subtitle = RegExp(r'([(\[{].*?[)\]\}]|[/:\\].*$)');
        if (subtitle.allMatches(title).isNotEmpty) {
          title = title.replaceAll(subtitle, '');
        }
      }

      final titlePatterns = [
        MapEntry(
            RegExp(
                r'[({\[](\d{4}|omnibus|anthology|hardcover|audiobook|audio\scd|paperback|turtleback|mass\s*market|edition|ed\.)[\])}]',
                caseSensitive: false),
            ''),
        MapEntry(
            RegExp(r'[({\[].*?(edition|ed.).*?[\]})]', caseSensitive: false),
            ''),
        MapEntry(RegExp(r'(\d+),(\d+)'), r'$1$2'),
        MapEntry(RegExp(r'(\s-)'), ' '),
        MapEntry(RegExp(r'''[:,;!@$%^&*(){}.`~"\s\[\]/]《》「」“”'''), ' '),
      ];

      for (final entry in titlePatterns) {
        title = title.replaceAll(entry.key, entry.value);
      }

      List<String> tokens = title.split(' ');
      for (var tok in tokens) {
        tok = tok.trim().replaceAll('"', '').replaceAll("'", "");
        if (tok.isNotEmpty &&
            (!stripJoiners ||
                !['a', 'and', 'the', '&'].contains(tok.toLowerCase()))) {
          results.add(tok);
        }
      }
    }

    return results;
  }

  List<String> getAuthorTokens(
    List<String> authors, {
    bool onlyFirstAuthor = true,
  }) {
    final removePattern = RegExp(r'[!@#$%^&*()（）「」{}`~"\s\[\]/]');
    final replacePattern = RegExp(r'[-+.:;,，。；：]');

    if (onlyFirstAuthor) {
      authors = authors.take(1).toList();
    }

    return authors.expand((au) {
      final hasComma = au.contains(',');
      au = replacePattern.allMatches(au).join(' ');
      List<String> parts = au.split(' ');

      if (hasComma) {
        parts = parts.sublist(1) + parts.sublist(0, 1);
      }

      return parts
          .map((tok) {
            tok = removePattern.allMatches(tok).join('').trim();
            return (tok.length > 2 &&
                    !['von', 'van', 'unknown'].contains(tok.toLowerCase()))
                ? tok
                : null;
          })
          .where((tok) => tok != null)
          .cast<String>();
    }).toList();
  }

  String buildTerm(String type, List<String> parts) {
    return parts.join(' ');
  }
}
