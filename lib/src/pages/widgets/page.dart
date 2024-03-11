import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final Color color;
    if (theme.brightness == Brightness.light) {
      color = Colors.white70;
    } else {
      color = Colors.grey[900]!;
    }
    return Card(
      margin: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: color,
      elevation: 2.0,
      child: child,
    );
  }
}
