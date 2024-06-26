import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/extensions/translate.dart';
import 'package:eh_tagger/src/calibre/metadata.dart';
import 'package:eh_tagger/src/ehentai/extensions/query.dart';
import 'package:eh_tagger/src/ehentai/network.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class EHentai with EHentaiNetworkHandler {
  final metadataMap = <int, CalibreMetadata>{};
  late final bool useExHentai;
  late final bool chineseEHentai;
  late final String transDbPath;
  Database? transDb;

  EHentai({required Settings settings}) {
    useExHentai = settings.useExHentai.value;
    chineseEHentai = settings.chineseEHentai.value;
    if (AppStorage.transDbExists()) {
      transDbPath = AppStorage.transDbPath;
    } else {
      transDbPath = '';
      settings.setTransDbVersion('');
    }
    initDio(
      useCookie: settings.useExHentai.value,
      useProxy: settings.useProxy.value,
      proxyLink: settings.proxyLink.value,
      ipbMemberId: settings.ipbMemberId.value,
      ipbPassHash: settings.ipbPassHash.value,
      igneous: settings.igneous.value,
    );
  }

  Future<void> initTransDb(Logs logs) async {
    logs.info('Initializing translation database');
    transDb = await databaseFactoryFfi.openDatabase(transDbPath);
  }

  Future<void> closeTransDb(Logs logs) async {
    logs.info('Closing translation database');
    await transDb?.close();
  }

  Future<void> identify({
    String? title,
    List<String>? authors,
    Map<String, dynamic>? identifiers,
    String eHentaiUrl = '',
    required int id,
  }) async {
    if (eHentaiUrl.isNotEmpty) {
      final gidlist = getGidlist(eHentaiUrl);
      if (gidlist == null) {
        throw Exception('Failed to get gidlist: $eHentaiUrl');
      }
      try {
        await getAllDetails(gidlist, title, id);
        return;
      } catch (_) {
        rethrow;
      }
    }
    final query = createQuery(
      title: title,
      useExHentai: useExHentai,
    );
    if (query == null || query.isEmpty) {
      throw Exception('Insufficient metadata to construct query');
    }

    final raw = await getHtmlContent(query);

    final gidlist = getGidlist(raw);
    if (gidlist == null) {
      throw Exception('Failed to get gidlist: $query');
    }

    final detailQuery = createQueryDetail(
      title: title,
      authors: authors,
      identifiers: identifiers,
      useExHentai: useExHentai,
    );
    if (detailQuery == null || detailQuery.isEmpty) {
      throw Exception('Insufficient metadata to construct detail query');
    }
    try {
      await getAllDetails(gidlist, title!, id);
      return;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> translateMetadata() async {
    if (transDb == null) return;
    if (metadataMap.isEmpty) return;
    for (final id in metadataMap.keys) {
      if (metadataMap[id] == null) continue;
      try {
        await TranslateExtension.translate(transDb, metadataMap[id]!);
      } catch (_) {
        rethrow;
      }
    }
  }
}
