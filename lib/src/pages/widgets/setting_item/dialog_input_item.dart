import 'package:eh_tagger/src/pages/widgets/setting_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class DialogInputItem extends StatefulWidget {
  final String name;
  final IconData icon;
  final RxString rxString;
  final void Function(String) updateValue;
  final bool hideText;

  const DialogInputItem({
    super.key,
    required this.name,
    required this.icon,
    required this.rxString,
    required this.updateValue,
    this.hideText = false,
  });

  @override
  State<DialogInputItem> createState() => _DialogInputItemState();
}

class _DialogInputItemState extends State<DialogInputItem> {
  Text buildText(bool hideText, String rxString) {
    return Text(
      hideText
          ? (rxString.isEmpty ? AppLocalizations.of(context)!.notSet : '******')
          : (rxString.isEmpty
              ? AppLocalizations.of(context)!.notSet
              : rxString),
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.normal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      name: widget.name,
      icon: widget.icon,
      widget: Obx(
        () => Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                  onTap: () async {
                    final controller =
                        TextEditingController(text: widget.rxString.value);
                    final value = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.enterValue),
                        content: TextField(
                          controller: controller,
                          onSubmitted: (value) {
                            Navigator.of(context).pop(value);
                          },
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(AppLocalizations.of(context)!.save),
                            onPressed: () {
                              Navigator.of(context).pop(controller.text);
                            },
                          ),
                        ],
                      ),
                    );
                    if (value != null && value != widget.rxString.value) {
                      widget.updateValue(value);
                    }
                  },
                  child: buildText(widget.hideText, widget.rxString.value)),
            )),
      ),
    );
  }
}
