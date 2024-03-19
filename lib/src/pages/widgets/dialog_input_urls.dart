import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DialogInputUrls extends StatefulWidget {
  final List<String> failedUrls;

  const DialogInputUrls({
    super.key,
    required this.failedUrls,
  });

  @override
  State<DialogInputUrls> createState() => _DialogInputUrlsState();
}

class _DialogInputUrlsState extends State<DialogInputUrls> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.failedUrls.isNotEmpty) {
      _controller.text = widget.failedUrls.join('\n');
      _controller.text += '\n';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.inputEHentaiUrl),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'https://e-hentai.org/g/123456/abcdef1234/',
          border: OutlineInputBorder(),
        ),
        maxLines: null,
        minLines: 5,
        keyboardType: TextInputType.multiline,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.text
                .split('\n')
                .map((line) {
                  line = line.trim();
                  if (line.isEmpty) return null;
                  if (!line.endsWith('/')) {
                    // Add trailing slash
                    line = '$line/';
                  }
                  return line;
                })
                .where((line) => line != null)
                .map((line) => line!)
                .toSet()
                .toList());
          },
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}
