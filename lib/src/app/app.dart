import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/themes.dart';
import 'package:eh_tagger/src/pages/window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MaterialApp(
        theme: AppThemes.light(),
        darkTheme: AppThemes.dark(),
        themeMode: Get.find<Settings>().mode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('zh', ''),
        ],
        home: const AppWindow(),
      ),
    );
  }
}
