import 'dart:convert';
import 'dart:io';

import 'package:eh_tagger/src/app/config.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Settings extends GetxController {
  final Rx<ThemeMode> _mode;
  final RxBool _inputEHentaiUrl;
  final RxBool _useExHentai;
  final RxBool _chineseEHentai;
  final RxBool _useProxy;
  final RxString _proxyLink;
  final RxString _ipbMemberId;
  final RxString _ipbPassHash;
  final RxString _igneous;
  final RxBool _addBooksAfterDownload;
  final RxBool _fetchMetadataAfterDownload;
  final RxBool _delSourceBooks;
  final RxBool _saveOpf;
  final RxString _calibredbPath;
  final RxString _metadataDbPath;
  final RxBool _netDriveOptimization;
  final RxString _transDbVersion;
  late final bool _dbInitialized;

  late final Config _config;

  Settings(
    this._mode,
    this._inputEHentaiUrl,
    this._useExHentai,
    this._chineseEHentai,
    this._useProxy,
    this._proxyLink,
    this._ipbMemberId,
    this._ipbPassHash,
    this._igneous,
    this._addBooksAfterDownload,
    this._fetchMetadataAfterDownload,
    this._delSourceBooks,
    this._saveOpf,
    this._calibredbPath,
    this._metadataDbPath,
    this._netDriveOptimization,
    this._transDbVersion,
  );

  factory Settings.fromConfig(Config config) {
    final settings = Settings(
      ThemeMode.values[config.mode].obs,
      config.inputEHentaiUrl.obs,
      config.useExHentai.obs,
      config.chineseEHentai.obs,
      config.useProxy.obs,
      config.proxyLink.obs,
      config.ipbMemberId.obs,
      config.ipbPassHash.obs,
      config.igneous.obs,
      config.addBooksAfterDownload.obs,
      config.fetchMetadataAfterDownload.obs,
      config.delSourceBooks.obs,
      config.saveOpf.obs,
      config.calibredbPath.obs,
      config.metadataDbPath.obs,
      config.netDriveOptimization.obs,
      config.transDbVersion.obs,
    );
    settings._config = config;
    return settings;
  }

  factory Settings.loadConfig() {
    final defaultConfig = Config.defaultConfig();
    final file = File(AppStorage.configPath);
    final logs = Get.find<Logs>();
    dynamic json;
    if (file.existsSync()) {
      try {
        json = jsonDecode(file.readAsStringSync());
      } on FormatException catch (e) {
        logs.error('Failed to decode config: $e');
        logs.error('Using default config');
        file.writeAsStringSync(jsonEncode(defaultConfig.toJson()));
      }
      final defaultConfigJson = defaultConfig.toJson();
      bool isMissing = false;
      for (final key in defaultConfigJson.keys) {
        if (!json.containsKey(key)) {
          json[key] = defaultConfigJson[key];
          isMissing = true;
        }
      }
      if (isMissing) {
        logs.warning('Config missing keys, updating');
        file.writeAsStringSync(jsonEncode(json));
      }
      final config = Config.fromJson(json);
      if (AppStorage.transDbExists()) {
        if (config.transDbVersion.isEmpty) {
          logs.warning('Translation database version not found');
        } else {
          logs.info('Translation Database path: ${AppStorage.transDbPath}');
        }
      } else {
        logs.warning('Translation database not found');
        config.transDbVersion = '';
      }
      return Settings.fromConfig(config);
    } else {
      file.createSync(recursive: true);
      logs.warning('Config file not found, creating');
      final config = defaultConfig;
      file.writeAsStringSync(jsonEncode(config.toJson()));
      return Settings.fromConfig(config);
    }
  }
}

extension SettingsExtension on Settings {
  ThemeMode get mode => _mode.value;

  RxBool get inputEHentaiUrl => _inputEHentaiUrl;

  RxBool get useExHentai => _useExHentai;

  RxBool get chineseEHentai => _chineseEHentai;

  RxBool get useProxy => _useProxy;

  RxString get proxyLink => _proxyLink;

  RxString get ipbMemberId => _ipbMemberId;

  RxString get ipbPassHash => _ipbPassHash;

  RxString get igneous => _igneous;

  RxBool get addBooksAfterDownload => _addBooksAfterDownload;

  RxBool get fetchMetadataAfterDownload => _fetchMetadataAfterDownload;

  RxBool get delSourceBooks => _delSourceBooks;

  RxBool get saveOpf => _saveOpf;

  RxString get calibredbPath => _calibredbPath;

  RxString get metadataDbPath => _metadataDbPath;

  RxBool get netDriveOptimization => _netDriveOptimization;

  RxString get transDbVersion => _transDbVersion;

  bool get dbInitialized => _dbInitialized;

  void _saveConfig() {
    final file = File(AppStorage.configPath);
    file.writeAsStringSync(jsonEncode(_config.toJson()));
    /*
    final logs = Get.find<Logs>();
    logs.info('Config saved');
     */
  }

  void setTheme(int index) {
    _mode.value = ThemeMode.values[index];
    _config.mode = index;
    _saveConfig();
  }

  void setInputEHentaiUrl(bool value) {
    _inputEHentaiUrl.value = value;
    _config.inputEHentaiUrl = value;
    _saveConfig();
  }

  void setUseExHentai(bool value) {
    _useExHentai.value = value;
    _config.useExHentai = value;
    _saveConfig();
  }

  void setChineseEHentai(bool value) {
    _chineseEHentai.value = value;
    _config.chineseEHentai = value;
    _saveConfig();
  }

  void setUseProxy(bool value) {
    _useProxy.value = value;
    _config.useProxy = value;
    _saveConfig();
  }

  void setProxyLink(String value) {
    _proxyLink.value = value;
    _config.proxyLink = value;
    _saveConfig();
  }

  void setIpbMemberId(String value) {
    _ipbMemberId.value = value;
    _config.ipbMemberId = value;
    _saveConfig();
  }

  void setIpbPassHash(String value) {
    _ipbPassHash.value = value;
    _config.ipbPassHash = value;
    _saveConfig();
  }

  void setIgneous(String value) {
    _igneous.value = value;
    _config.igneous = value;
    _saveConfig();
  }

  void setAddBooksAfterDownload(bool value) {
    _addBooksAfterDownload.value = value;
    _config.addBooksAfterDownload = value;
    _saveConfig();
  }

  void setFetchMetadataAfterDownload(bool value) {
    _fetchMetadataAfterDownload.value = value;
    _config.fetchMetadataAfterDownload = value;
    _saveConfig();
  }

  void setDelSourceBooks(bool value) {
    _delSourceBooks.value = value;
    _config.delSourceBooks = value;
    _saveConfig();
  }

  void setSaveOpf(bool value) {
    _saveOpf.value = value;
    _config.saveOpf = value;
    _saveConfig();
  }

  void setCalibredbPath(String value) {
    _calibredbPath.value = value;
    _config.calibredbPath = value;
    _saveConfig();
  }

  void setMetadataDbPath(String value) {
    _metadataDbPath.value = value;
    _config.metadataDbPath = value;
    _saveConfig();
  }

  void setTransDbVersion(String value) {
    _transDbVersion.value = value;
    _config.transDbVersion = value;
    _saveConfig();
  }

  void setNetDriveOptimization(bool value) {
    _netDriveOptimization.value = value;
    _config.netDriveOptimization = value;
    _saveConfig();
  }

  void setDbInitialized(bool value) {
    // should only call once
    _dbInitialized = value;
  }
}
