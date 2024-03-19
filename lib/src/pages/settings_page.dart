import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item/db_item.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item/dialog_input_item.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item/popup_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildSettingItems(List<Widget> children) {
      return Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? Colors.grey[350]!
              : Colors.grey[850]!,
          border: Border.all(
            color: theme.brightness == Brightness.light
                ? Colors.grey[400]!
                : Colors.grey[800]!,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: ListView.separated(
          itemCount: children.length,
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(height: 0.0);
          },
          itemBuilder: (BuildContext context, int index) {
            return children[index];
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      );
    }

    final settings = Get.find<Settings>();
    final themeModes = <String>[
      AppLocalizations.of(context)!.system,
      AppLocalizations.of(context)!.light,
      AppLocalizations.of(context)!.dark,
    ];
    final items = [
      buildSettingItems([
        SettingItem(
          name: AppLocalizations.of(context)!.theme,
          icon: Icons.brush,
          widget: Obx(
            () => CustomPopupMenuButton<String>(
              value: themeModes[settings.mode.index],
              items: themeModes
                  .map((e) => PopupMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (value) =>
                  settings.setTheme(themeModes.indexOf(value!)),
            ),
          ),
        ),
      ]),
      buildSettingItems([
        SettingItem(
          name: AppLocalizations.of(context)!.inputEHentaiUrl,
          icon: Icons.link,
          widget: Obx(
            () => Switch(
              value: settings.inputEHentaiUrl.value,
              onChanged: (value) => settings.setInputEHentaiUrl(value),
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.chineseEHentai,
          icon: Icons.language,
          widget: Obx(
            () => Switch(
              value: settings.chineseEHentai.value,
              onChanged: (value) => settings.setChineseEHentai(value),
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.useExHentai,
          icon: Icons.keyboard_option_key,
          widget: Obx(
            () => Switch(
              value: settings.useExHentai.value,
              onChanged: (value) => settings.setUseExHentai(value),
            ),
          ),
        ),
      ]),
      buildSettingItems([
        SettingItem(
          name: AppLocalizations.of(context)!.useProxy,
          icon: Icons.vpn_key,
          widget: Obx(
            () => Switch(
              value: settings.useProxy.value,
              onChanged: (value) {
                settings.setUseProxy(value);
                final downloader = Get.find<Downloader>();
                if (value) {
                  downloader.setProxy(settings.proxyLink.value);
                } else {
                  downloader.setProxy('');
                }
              },
            ),
          ),
        ),
        DialogInputItem(
          name: AppLocalizations.of(context)!.proxyLink,
          icon: Icons.http,
          rxString: settings.proxyLink,
          updateValue: (value) => settings.setProxyLink(value),
        ),
      ]),
      buildSettingItems([
        DialogInputItem(
          name: AppLocalizations.of(context)!.ipbMemberId,
          icon: Icons.person,
          rxString: settings.ipbMemberId,
          updateValue: (value) => settings.setIpbMemberId(value),
          hideText: true,
        ),
        DialogInputItem(
          name: AppLocalizations.of(context)!.ipbPassHash,
          icon: Icons.password,
          rxString: settings.ipbPassHash,
          updateValue: (value) => settings.setIpbPassHash(value),
          hideText: true,
        ),
        DialogInputItem(
          name: AppLocalizations.of(context)!.igneous,
          icon: Icons.cookie,
          rxString: settings.igneous,
          updateValue: (value) => settings.setIgneous(value),
          hideText: true,
        ),
      ]),
      buildSettingItems([
        SettingItem(
          name: AppLocalizations.of(context)!.showFailedUrls,
          icon: Icons.error,
          widget: Obx(
            () => Switch(
              value: settings.showFailedUrls.value,
              onChanged: (value) => settings.setShowFailedUrls(value),
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.addBooksAfterDownload,
          icon: Icons.add_box,
          widget: Obx(
            () => Switch(
              value: settings.addBooksAfterDownload.value,
              onChanged: (value) {
                if (value) {
                  settings.setAddBooksAfterDownload(true);
                } else {
                  settings.setAddBooksAfterDownload(false);
                  settings.setFetchMetadataAfterDownload(false);
                }
              },
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.fetchMetadataAfterDownload,
          icon: Icons.get_app,
          widget: Obx(
            () => Switch(
              value: settings.fetchMetadataAfterDownload.value,
              onChanged: (value) {
                if (value) {
                  settings.setAddBooksAfterDownload(true);
                  settings.setFetchMetadataAfterDownload(true);
                } else {
                  settings.setFetchMetadataAfterDownload(false);
                }
              },
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.delSourceBooks,
          icon: Icons.delete,
          widget: Obx(
            () => Switch(
              value: settings.delSourceBooks.value,
              onChanged: (value) => settings.setDelSourceBooks(value),
            ),
          ),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.saveOpf,
          icon: Icons.save,
          widget: Obx(
            () => Switch(
              value: settings.saveOpf.value,
              onChanged: (value) => settings.setSaveOpf(value),
            ),
          ),
        ),
      ]),
      buildSettingItems([
        DialogInputItem(
          name: AppLocalizations.of(context)!.calibredbPath,
          icon: Icons.arrow_circle_right_outlined,
          rxString: settings.calibredbPath,
          updateValue: (value) => settings.setCalibredbPath(value),
        ),
        DialogInputItem(
          name: AppLocalizations.of(context)!.metadataDbPath,
          icon: Icons.storage,
          rxString: settings.metadataDbPath,
          updateValue: (value) => settings.setMetadataDbPath(value),
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.netDriveOptimization,
          icon: Icons.network_check,
          widget: Obx(
            () => Switch(
              value: settings.netDriveOptimization.value,
              onChanged: (value) => settings.setNetDriveOptimization(value),
            ),
          ),
        ),
      ]),
      buildSettingItems([
        DbItem(
          name: AppLocalizations.of(context)!.transDbVersion,
          icon: Icons.translate,
        ),
        SettingItem(
          name: AppLocalizations.of(context)!.appVersion,
          icon: Icons.info,
          widget: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              appVersion,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.normal),
            ),
          ),
        ),
      ]),
    ];
    return AppPage(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 12.0);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return items[index];
                  },
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
