import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  int mode;
  bool inputEHentaiUrl;
  bool useExHentai;
  bool chineseEHentai;
  bool useProxy;
  String proxyLink;
  String ipbMemberId;
  String ipbPassHash;
  String igneous;
  bool showFailedUrls;
  bool addBooksAfterDownload;
  bool fetchMetadataAfterDownload;
  bool delSourceBooks;
  bool saveOpf;
  String calibredbPath;
  String metadataDbPath;
  String transDbVersion;
  bool netDriveOptimization;

  Config({
    required this.mode,
    required this.inputEHentaiUrl,
    required this.useExHentai,
    required this.chineseEHentai,
    required this.useProxy,
    required this.proxyLink,
    required this.ipbMemberId,
    required this.ipbPassHash,
    required this.igneous,
    required this.showFailedUrls,
    required this.addBooksAfterDownload,
    required this.fetchMetadataAfterDownload,
    required this.delSourceBooks,
    required this.saveOpf,
    required this.calibredbPath,
    required this.metadataDbPath,
    required this.transDbVersion,
    required this.netDriveOptimization,
  });

  factory Config.defaultConfig() => Config(
        mode: 0,
        inputEHentaiUrl: false,
        useExHentai: false,
        chineseEHentai: false,
        useProxy: false,
        proxyLink: '127.0.0.1:8080',
        ipbMemberId: '',
        ipbPassHash: '',
        igneous: '',
        showFailedUrls: false,
        addBooksAfterDownload: false,
        fetchMetadataAfterDownload: false,
        delSourceBooks: false,
        saveOpf: true,
        calibredbPath: '',
        metadataDbPath: '',
        transDbVersion: '',
        netDriveOptimization: false,
      );

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
