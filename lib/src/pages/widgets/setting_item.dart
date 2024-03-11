import 'package:flutter/material.dart';

class SettingItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final Widget widget;

  const SettingItem({
    super.key,
    required this.name,
    required this.icon,
    required this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
      ),
      title: Text(name, style: Theme.of(context).textTheme.titleSmall),
      trailing: widget,
    );
  }
}
