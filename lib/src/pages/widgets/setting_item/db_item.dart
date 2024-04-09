import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/ehentai/translation_database.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class DbItem extends StatelessWidget {
  final String name;
  final IconData icon;

  const DbItem({
    super.key,
    required this.name,
    required this.icon,
  });

  Text buildText(String rxString, BuildContext context) {
    return Text(
      rxString.isEmpty ? AppLocalizations.of(context)!.notDetected : rxString,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.normal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();
    final transDbVersion = settings.transDbVersion;
    return SettingItem(
      name: name,
      icon: icon,
      widget: Obx(
        () => Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                  onTap: () async {
                    if (!AppStorage.transDbExists()) {
                      settings.setTransDbVersion('');
                    }
                    final value = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title:
                            Text(AppLocalizations.of(context)!.transDbVersion),
                        content: Text(
                            '${AppLocalizations.of(context)!.transDbVersion}: ${transDbVersion.value.isEmpty ? AppLocalizations.of(context)!.notDetected : transDbVersion.value}'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                                AppLocalizations.of(context)!.updateTransDb),
                          ),
                        ],
                      ),
                    );
                    if (value != null && value) {
                      final updater = TranslationDatabaseUpdater(settings);
                      late final String latestVersion;
                      try {
                        latestVersion = await updater.getLatestVersion();
                      } catch (e) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content: Text('$e'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      if (!updater.shouldUpdate(
                          transDbVersion.value, latestVersion)) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                                AppLocalizations.of(context)!.noUpdateNeeded),
                            content: Text(AppLocalizations.of(context)!
                                .noUpdateNeededDesc),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      try {
                        final tempFilePath =
                            await updater.downloadArchive(latestVersion);
                        final transDbArchivePath =
                            await updater.unzipArchive(tempFilePath);
                        final transDb = TranslationDatabase();
                        await transDb.init(transDbArchivePath);
                        settings.setTransDbVersion(latestVersion);
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .updateTransDbSuccess),
                            content: Text(
                                '${AppLocalizations.of(context)!.transDbVersion} $latestVersion'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content: Text(
                                'Failed to update translation database: $e'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(AppLocalizations.of(context)!.ok),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                    }
                  },
                  child: buildText(transDbVersion.value, context)),
            )),
      ),
    );
  }
}
