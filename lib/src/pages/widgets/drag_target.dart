import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class DragTargetWidget extends StatefulWidget {
  final List<Book> books;
  final VoidCallback onBooksChanged;

  const DragTargetWidget({
    super.key,
    required this.books,
    required this.onBooksChanged,
  });

  @override
  State<DragTargetWidget> createState() => _DragTargetWidgetState();
}

class _DragTargetWidgetState extends State<DragTargetWidget> {
  final _xFiles = <XFile>[];
  bool _dragging = false;

  Future<void> addBooks() async {
    try {
      final addedBooks =
          await BookHandler.addBooks(context: context, xFiles: _xFiles);
      if (addedBooks.isEmpty) {
        return;
      }
      setState(() {
        widget.books.insertAll(0, addedBooks.reversed);
        widget.onBooksChanged();
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addBooks),
            content: Text(AppLocalizations.of(context)!
                .addBooksSuccess(addedBooks.length)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          );
        },
      );
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to add books: $e');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text('Failed to add books: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          );
        },
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        _xFiles.addAll(detail.files);
        addBooks().then(
          (_) => setState(() {
            _xFiles.clear();
          }),
        );
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Builder(
        builder: (context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Icon(
              Icons.upload,
              size: 100,
              color: _dragging ? Colors.blue : Colors.transparent,
            ),
          );
        },
      ),
    );
  }
}
