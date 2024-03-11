import 'package:background_downloader/background_downloader.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/ehentai/network.dart';

class EHArchive {
  final String name;
  final String galleryUrl;
  final String archiveUrl;

  EHArchive({
    required this.name,
    required this.galleryUrl,
    required this.archiveUrl,
  });
}

class ArchiveDownloadHandler with EHentaiNetworkHandler {
  final tasks = <DownloadTask>[];
  final List<String> urls;
  final Logs logs;

  ArchiveDownloadHandler({
    required this.urls,
    required Settings settings,
    required this.logs,
  }) {
    initDio(
      useCookie: true,
      useProxy: settings.useProxy.value,
      proxyLink: settings.proxyLink.value,
      ipbMemberId: settings.ipbMemberId.value,
      ipbPassHash: settings.ipbPassHash.value,
      igneous: settings.igneous.value,
    );
  }

  Future<List<EHArchive>> getArchives() async {
    final futures = <Future>[];
    final archives = <EHArchive>[];
    for (final url in urls) {
      futures.add(() async {
        try {
          archives.add(await getArchiveData(url));
        } catch (e) {
          logs.error('Failed to get archive url for $url: $e');
        }
      }());
    }
    await Future.wait(futures);
    return archives;
  }
}
