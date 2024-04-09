import 'package:eh_tagger/src/pages/widgets/setting_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class DialogInputItem extends StatelessWidget {
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

  Text buildText(bool hideText, String rxString, BuildContext context) {
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
      name: name,
      icon: icon,
      widget: Obx(
        () => Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                  onTap: () async {
                    final controller =
                        TextEditingController(text: rxString.value);
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
                    if (value != null && value != rxString.value) {
                      updateValue(value);
                    }
                  },
                  child: buildText(hideText, rxString.value, context)),
            )),
      ),
    );
  }
}
