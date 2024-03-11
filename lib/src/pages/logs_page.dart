import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = Get.find<Logs>();
    return AppPage(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.logs),
          actions: [
            IconButton(
              color: theme.colorScheme.primary,
              icon: const Icon(Icons.delete),
              tooltip: AppLocalizations.of(context)!.clearLogs,
              onPressed: () {
                logs.clear();
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            left: 12.0,
            right: 12.0,
          ),
          child: Obx(() {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (logs.data.isNotEmpty) {
                _controller.jumpTo(_controller.position.maxScrollExtent);
              }
            });
            return ListView.builder(
              controller: _controller,
              itemCount: logs.data.length,
              itemBuilder: (context, index) {
                final log = logs.data[index];
                final levelColor = () {
                  switch (log.level) {
                    case 'INFO':
                      return Colors.blue;
                    case 'WARN':
                      return Colors.orange;
                    case 'ERROR':
                      return Colors.red;
                    default:
                      return theme.textTheme.titleSmall?.color;
                  }
                }();

                return RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: '${log.timestamp} ',
                    style: TextStyle(
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      color: theme.textTheme.titleSmall?.color,
                    ),
                  ),
                  TextSpan(
                    text: '${log.level} ',
                    style: TextStyle(
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      color: levelColor,
                    ),
                  ),
                  TextSpan(
                    text: log.message,
                    style: TextStyle(
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      color: theme.textTheme.titleSmall?.color,
                    ),
                  ),
                ]));
              },
            );
          }),
        ),
      ),
    );
  }
}
