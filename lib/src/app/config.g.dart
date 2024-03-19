// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      mode: json['mode'] as int,
      inputEHentaiUrl: json['inputEHentaiUrl'] as bool,
      useExHentai: json['useExHentai'] as bool,
      chineseEHentai: json['chineseEHentai'] as bool,
      useProxy: json['useProxy'] as bool,
      proxyLink: json['proxyLink'] as String,
      ipbMemberId: json['ipbMemberId'] as String,
      ipbPassHash: json['ipbPassHash'] as String,
      igneous: json['igneous'] as String,
      showFailedUrls: json['showFailedUrls'] as bool,
      addBooksAfterDownload: json['addBooksAfterDownload'] as bool,
      fetchMetadataAfterDownload: json['fetchMetadataAfterDownload'] as bool,
      delSourceBooks: json['delSourceBooks'] as bool,
      saveOpf: json['saveOpf'] as bool,
      calibredbPath: json['calibredbPath'] as String,
      metadataDbPath: json['metadataDbPath'] as String,
      transDbVersion: json['transDbVersion'] as String,
      netDriveOptimization: json['netDriveOptimization'] as bool,
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'mode': instance.mode,
      'inputEHentaiUrl': instance.inputEHentaiUrl,
      'useExHentai': instance.useExHentai,
      'chineseEHentai': instance.chineseEHentai,
      'useProxy': instance.useProxy,
      'proxyLink': instance.proxyLink,
      'ipbMemberId': instance.ipbMemberId,
      'ipbPassHash': instance.ipbPassHash,
      'igneous': instance.igneous,
      'showFailedUrls': instance.showFailedUrls,
      'addBooksAfterDownload': instance.addBooksAfterDownload,
      'fetchMetadataAfterDownload': instance.fetchMetadataAfterDownload,
      'delSourceBooks': instance.delSourceBooks,
      'saveOpf': instance.saveOpf,
      'calibredbPath': instance.calibredbPath,
      'metadataDbPath': instance.metadataDbPath,
      'transDbVersion': instance.transDbVersion,
      'netDriveOptimization': instance.netDriveOptimization,
    };
