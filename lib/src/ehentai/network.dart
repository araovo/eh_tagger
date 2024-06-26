import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/ehentai/archive.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';
import 'package:get/get.dart' hide FormData;
import 'package:html_unescape/html_unescape.dart';

mixin EHentaiNetworkHandler {
  final dio = Dio();
  final List<Map<String, String>> cookies = [];

  void initDio({
    required bool useCookie,
    required bool useProxy,
    required String proxyLink,
    required String ipbMemberId,
    required String ipbPassHash,
    required String igneous,
  }) {
    final logs = Get.find<Logs>();
    logs.info('Initializing Dio');
    dio.options.headers['User-Agent'] = userAgent;
    dio.options.connectTimeout = httpTimeout;
    dio.options.receiveTimeout = httpTimeout;
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      retries: retries,
      retryDelays: retryDelays,
      logPrint: (log) {
        logs.warning(log);
      },
    ));
    if (useProxy && proxyLink.isNotEmpty) {
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
    setCookie(
      useCookie: useCookie,
      ipbMemberId: ipbMemberId,
      ipbPassHash: ipbPassHash,
      igneous: igneous,
    );
  }

  void setCookie({
    required bool useCookie,
    required String ipbMemberId,
    required String ipbPassHash,
    required String igneous,
  }) {
    final logs = Get.find<Logs>();
    if (!useCookie) {
      logs.info('Disabling cookie for download tasks');
      dio.options.headers.remove('Cookie');
    } else {
      if (ipbMemberId.isEmpty || ipbPassHash.isEmpty || igneous.isEmpty) {
        throw Exception('Cookies are required');
      }
    }
    logs.info('Using cookie for download tasks');
    cookies.addAll([
      {
        'name': 'ipb_member_id',
        'value': ipbMemberId,
        'domain': '.exhentai.org',
        'path': '/'
      },
      {
        'name': 'ipb_pass_hash',
        'value': ipbPassHash,
        'domain': '.exhentai.org',
        'path': '/'
      },
      {
        'name': 'igneous',
        'value': igneous,
        'domain': '.exhentai.org',
        'path': '/'
      },
    ]);
    dio.options.headers['Cookie'] =
        cookies.map((e) => '${e['name']}=${e['value']}').toList().join('; ');
  }

  Future<String> getHtmlContent(String url) async {
    try {
      final response = await dio.get(url);
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Failed to get $url');
      }
      final data = response.data;
      if (data.contains('Your IP address has been temporarily banned')) {
        throw Exception('IP address has been temporarily banned');
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<EHArchive> getArchiveData(String eHentaiUrl) async {
    // get gidlist
    final gidlist = getGidlist(eHentaiUrl);
    if (gidlist == null) {
      throw Exception('Failed to get gidlist: $eHentaiUrl');
    }

    // get archive page url
    final galleryRaw = await getHtmlContent(eHentaiUrl);
    // parse "<a href="#" onclick="return popUp('url',480,320)">Archive Download</a></p>"
    final archivePagePatten = RegExp(
        r'''onclick="return popUp\('(.*?)',\d+,\d+\)">Archive Download''');
    final archivePageMatch = archivePagePatten.firstMatch(galleryRaw);
    if (archivePageMatch == null) {
      throw Exception('Failed to get archive url: $galleryRaw');
    }
    final htmlUnescape = HtmlUnescape();
    final archivePageUrl = htmlUnescape.convert(archivePageMatch.group(1)!);

    // post to archive page
    final archivePageRaw = await _postToArchivePage(archivePageUrl);

    // parse "document.location = "url""
    final urlPatten = RegExp(r'document.location = "(.+)"');
    final urlMatch = urlPatten.firstMatch(archivePageRaw);
    if (urlMatch == null) {
      throw Exception('Failed to get archive download url: $archivePageRaw');
    }
    final archiveDownloadPageUrl = urlMatch.group(1)!;

    // get archive raw
    String archiveDownloadPageRaw;
    try {
      archiveDownloadPageRaw = await _runArchiveTask(
        task: _getArchiveDownloadPage,
        url: archiveDownloadPageUrl,
        verificationString: archiveDownloadPageString,
      );
      if (!archiveDownloadPageRaw.contains(archiveDownloadPageString)) {
        throw Exception(
            'Failed to get archive download page: $archiveDownloadPageRaw');
      }
    } catch (e) {
      rethrow;
    }

    // parse <strong>name</strong>
    final namePatten = RegExp(r'<strong>(.+)</strong>');
    final nameMatch = namePatten.firstMatch(archiveDownloadPageRaw);
    if (nameMatch == null) {
      throw Exception('Failed to get archive name: $archiveDownloadPageRaw');
    }
    final name = nameMatch.group(1)!;

    // get size
    final archiveUrl = '$archiveDownloadPageUrl$downloadStartSuffix';
    final responseHead = await dio.head(archiveUrl);
    final size = responseHead.headers.value('content-length');
    if (size == null) {
      throw Exception('Failed to get archive size: ${responseHead.headers}');
    }

    return EHArchive(
      name: name,
      size: int.parse(size),
      galleryUrl: eHentaiUrl,
      archiveUrl: archiveUrl,
    );
  }

  Future<String> _postToArchivePage(String archivePageUrl) async {
    final formData = FormData.fromMap({
      'dltype': 'org',
      'dlcheck': 'Download Original Archive',
    });
    final options = Options(validateStatus: (status) => status! < 500);
    final response =
        await dio.post(archivePageUrl, data: formData, options: options);
    String result;

    if (response.statusCode != HttpStatus.ok) {
      if (response.statusCode != HttpStatus.found) {
        throw Exception(
            'Failed to post to $archivePageUrl: ${response.statusCode}');
      }
    }
    if (response.statusCode == HttpStatus.found) {
      // redirect to new page
      final redirectedPageUrl = response.headers.value('location');
      if (redirectedPageUrl == null) {
        throw Exception(
            'Failed to get archive download page: ${response.data}');
      }
      final redirectedResponse = await dio.get(redirectedPageUrl);
      if (redirectedResponse.statusCode != HttpStatus.ok) {
        throw Exception(
            'Failed to get archive download page: ${redirectedResponse.statusCode}');
      }
      result = redirectedResponse.data as String;
    } else {
      result = response.data as String;
    }
    return result;
  }

  Future<String> _getArchiveDownloadPage(String archiveDownloadPageUrl) async {
    return await getHtmlContent(archiveDownloadPageUrl);
  }

  Future<String> _runArchiveTask({
    required Future<String> Function(String) task,
    required String url,
    required String verificationString,
  }) async {
    String result = '';
    final completer = Completer<String>();
    Timer? timer;
    timer = Timer.periodic(hentaiAtHomeDuration, (_) async {
      try {
        result = await task(url);
        if (result.contains(verificationString)) {
          timer?.cancel();
          completer.complete(result);
        }
      } catch (e) {
        timer?.cancel();
        completer.completeError(e);
      }
    });

    return completer.future.timeout(hentaiAtHomeTimeout, onTimeout: () {
      timer?.cancel();
      return result;
    });
  }

  List<List<String>>? getGidlist(String raw) {
    final pattern = RegExp(
      r'https://(?:e-hentai.org|exhentai.org)/g/(?<gallery_id>\d+)/(?<gallery_token>\w+)/',
    );
    final results = pattern.allMatches(raw);
    if (results.isEmpty) {
      return null;
    }
    final gidlist = <List<String>>[];
    for (final result in results) {
      gidlist.add([
        result.namedGroup('gallery_id')!,
        result.namedGroup('gallery_token')!
      ]);
    }
    return gidlist;
  }

  Future<Map<String, dynamic>> _postApi(String data) {
    // return a json object
    return dio.post(eHentaiApiUrl, data: data).then((response) {
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Failed to post to $eHentaiApiUrl');
      }
      final result = json.decode(response.data) as Map<String, dynamic>;
      return result;
    });
  }

  Future<List<Map<String, dynamic>>> getGmetadatas(
      List<List<String>> gidlist) async {
    final data = {
      'method': 'gdata',
      'gidlist': gidlist,
      'namespace': 1,
    };
    final json = jsonEncode(data);
    final result = await _postApi(json);
    return (result['gmetadata'] as List).cast<Map<String, dynamic>>();
  }
}
