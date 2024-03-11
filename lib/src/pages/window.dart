import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/ehentai/translation_database.dart';
import 'package:eh_tagger/src/pages/books_page.dart';
import 'package:eh_tagger/src/pages/logs_page.dart';
import 'package:eh_tagger/src/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class AppWindow extends StatefulWidget {
  const AppWindow({super.key});

  @override
  State<AppWindow> createState() => _AppWindowState();
}

class _AppWindowState extends State<AppWindow> {
  int _index = 0;

  Future<void> transDbTask() async {
    final settings = Get.find<Settings>();
    final transDbVersion = settings.transDbVersion.value;
    if (transDbVersion.isEmpty) {
      return;
    }
    // check translation database version
    final updater = TranslationDatabaseUpdater(settings);
    late final String latestVersion;
    try {
      latestVersion = await updater.getLatestVersion();
    } catch (_) {
      return;
    }
    if (updater.shouldUpdate(transDbVersion, latestVersion)) {
      if (!mounted) return;
      final updateConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.updateAvailable),
          content: Text(
            '${AppLocalizations.of(context)!.transDbVersion}: $transDbVersion\n'
            '${AppLocalizations.of(context)!.latestVersion}: $latestVersion',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.of(context)!.updateNow),
            ),
          ],
        ),
      );
      if (updateConfirm == true) {
        final tempFilePath = await updater.downloadArchive(latestVersion);
        final transDbArchivePath = await updater.unzipArchive(tempFilePath);
        final transDb = TranslationDatabase();
        await transDb.init(transDbArchivePath);
        settings.setTransDbVersion(latestVersion);
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.updateTransDbSuccess),
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
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero, () async {
        await transDbTask();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final Color color;
    if (theme.brightness == Brightness.light) {
      color = Colors.grey[350]!;
    } else {
      color = Colors.grey[850]!;
    }
    return Scaffold(
      backgroundColor: color,
      body: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.25),
            child: NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (int index) {
                setState(() {
                  _index = index;
                });
              },
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.book, size: 28),
                  label: Text(
                    AppLocalizations.of(context)!.books,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.list, size: 28),
                  label: Text(
                    AppLocalizations.of(context)!.logs,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings, size: 28),
                  label: Text(
                    AppLocalizations.of(context)!.settings,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: const [
                      BooksPage(),
                      LogsPage(),
                      SettingsPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
