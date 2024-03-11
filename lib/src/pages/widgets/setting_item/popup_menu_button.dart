import 'package:flutter/material.dart';

class CustomPopupMenuButton<T> extends StatelessWidget {
  final T value;
  final List<PopupMenuItem<T>> items;
  final void Function(T?) onChanged;

  const CustomPopupMenuButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
            onTap: () async {
              final renderBox = context.findRenderObject() as RenderBox;
              await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  renderBox.localToGlobal(Offset.zero).dx,
                  renderBox.localToGlobal(Offset.zero).dy,
                  renderBox.localToGlobal(Offset.zero).dx,
                  renderBox.localToGlobal(Offset.zero).dy,
                ),
                items: items,
              ).then((T? value) {
                if (value != null) {
                  onChanged(value);
                }
              });
            },
            child: Text(value.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.normal,
                    ))),
      ),
    );
  }
}
