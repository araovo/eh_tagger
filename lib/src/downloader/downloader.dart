import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/database/dao/download_tasks.dart';
import 'package:eh_tagger/src/downloader/task.dart';
import 'package:eh_tagger/src/ehentai/network.dart';
import 'package:get/get.dart';

class Downloader extends GetxController with EHentaiNetworkHandler {
  final Logs logs;
  final taskDao = DownloadTasksDaoImpl();
  final _tasks = <DownloadTask>[].obs;
  final _cancelTokens = <int, CancelToken>{}; // id, cancelToken
  final failedUrls = <String>{};

  List<DownloadTask> get tasks => _tasks;

  Map<int, CancelToken> get cancelTokens => _cancelTokens;

  Downloader({
    required Settings settings,
    required this.logs,
  }) {
    initDio(
      useCookie: settings.useExHentai.value,
      useProxy: settings.useProxy.value,
      proxyLink: settings.proxyLink.value,
      ipbMemberId: settings.ipbMemberId.value,
      ipbPassHash: settings.ipbPassHash.value,
      igneous: settings.igneous.value,
    );
  }

  Future<void> queryTasks() async {
    // run during init
    final tasks = await taskDao.queryTasks();
    _tasks.addAll(tasks);
  }

  Future<void> setProxy(String proxyLink) async {
    if (proxyLink.isEmpty) {
      logs.info('Disabling proxy');
      dio.httpClientAdapter = IOHttpClientAdapter();
      return;
    }
    logs.info('Using proxy: $proxyLink');
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY $proxyLink';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
}
