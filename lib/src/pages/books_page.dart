import 'dart:io';

import 'package:eh_tagger/src/app/books.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/handler.dart';
import 'package:eh_tagger/src/calibre/opf.dart';
import 'package:eh_tagger/src/ehentai/ehentai.dart';
import 'package:eh_tagger/src/pages/widgets/drag_target.dart';
import 'package:eh_tagger/src/pages/widgets/edit_dialog.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  bool _addButtonEnabled = true;
  bool _updateButtonEnabled = true;
  bool _saveButtonEnabled = true;
  int? _selectedBookId;
  final _multiSelectedBookId = <int>{};
  final _coverBytes = Uint8List(0).obs;

  Widget buildBookList(bool isDarkMode) {
    final books = Get.find<BooksController>().books;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.separated(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final bookId = books[index].id;
              final title = books[index].metadata.title;
              final authors = books[index].metadata.authors?.join(', ');
              final publisher = books[index].metadata.publisher;
              final tags = books[index].metadata.tags?.join(', ');
              final authorsContent = authors != null && authors.isNotEmpty
                  ? '${AppLocalizations.of(context)!.authors}: $authors'
                  : '';
              final publisherContent = publisher != null && publisher.isNotEmpty
                  ? '${AppLocalizations.of(context)!.publisher}: $publisher'
                  : '';
              String content = '';
              if (authorsContent.isNotEmpty && publisherContent.isNotEmpty) {
                content = '$authorsContent $publisherContent';
              } else if (authorsContent.isNotEmpty) {
                content = authorsContent;
              } else if (publisherContent.isNotEmpty) {
                content = publisherContent;
              }
              final tagsContent = tags != null && tags.isNotEmpty
                  ? '${AppLocalizations.of(context)!.tags}: $tags'
                  : '';
              if (content.isNotEmpty) {
                content = '$content $tagsContent';
              } else {
                content = tagsContent;
              }
              return ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      color:
                          _selectedBookId != null && bookId == _selectedBookId
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2)
                              : isDarkMode
                                  ? Colors.grey[850]!
                                  : Colors.grey[350]!,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () async {
                          if (_selectedBookId != null &&
                              bookId == _selectedBookId) {
                            _selectedBookId = null;
                            _coverBytes.value = Uint8List(0);
                          } else {
                            _selectedBookId = bookId;
                            final cover = File(books[index].coverPath);
                            if (await cover.exists()) {
                              _coverBytes.value = await cover.readAsBytes();
                            } else {
                              _coverBytes.value = Uint8List(0);
                            }
                          }
                          setState(() {});
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              Checkbox(
                                value: _multiSelectedBookId.contains(bookId),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _multiSelectedBookId.add(bookId);
                                    } else {
                                      _multiSelectedBookId.remove(bookId);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    if (content.isNotEmpty)
                                      Text(
                                        content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                            ])),
                      ),
                    ),
                  ));
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 4);
            },
          ),
        ),
        const IgnorePointer(
          child: Center(
            child: DragTargetWidget(),
          ),
        ),
      ],
    );
  }

  Widget buildBookDetail() {
    String title = '';
    String eHentaiUrl = '';
    String? authors;
    String? publisher;
    String? tags;
    String? languages;
    double? rating;

    final booksController = Get.find<BooksController>();
    if (_selectedBookId != null) {
      final index = booksController.getIndex(_selectedBookId!);
      final book = booksController.getBook(index);
      title = book.metadata.title;
      eHentaiUrl = book.metadata.eHentaiUrl;
      authors = book.metadata.authors?.join(',');
      publisher = book.metadata.publisher;
      tags = book.metadata.tags?.join(', ');
      languages = book.metadata.languages?.join(', ');
      rating = book.metadata.rating;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (_selectedBookId != null) ...[
              Obx(() {
                if (_coverBytes.value.isNotEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.memory(_coverBytes.value),
                      const Divider()
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              if (eHentaiUrl.isNotEmpty)
                Text(
                  eHentaiUrl,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              if (authors != null && authors.isNotEmpty)
                Text(
                  '${AppLocalizations.of(context)!.authors}: $authors',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              if (publisher != null && publisher.isNotEmpty)
                Text(
                  '${AppLocalizations.of(context)!.publisher}: $publisher',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              if (tags != null && tags.isNotEmpty)
                Text(
                  '${AppLocalizations.of(context)!.tags}: $tags',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              if (languages != null && languages.isNotEmpty)
                Text(
                  '${AppLocalizations.of(context)!.languages}: $languages',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              if (rating != null)
                Text(
                  '${AppLocalizations.of(context)!.rating}: $rating',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Book> getSelectedBooks() {
    if (_multiSelectedBookId.isEmpty) {
      return [];
    }
    final ids = _multiSelectedBookId.toList()..sort();
    final books = Get.find<BooksController>().books;
    return books.where((book) => ids.contains(book.id)).toList();
  }

  Future<void> editSelectedBooks() async {
    await showDialog(
      context: context,
      builder: (context) {
        return EditDialog(
          books: getSelectedBooks(),
        );
      },
    );
    if (_selectedBookId != null) {
      final booksController = Get.find<BooksController>();
      final index = booksController.getIndex(_selectedBookId!);
      final book = Get.find<BooksController>().getBook(index);
      final cover = File(book.coverPath);
      if (await cover.exists()) {
        _coverBytes.value = await cover.readAsBytes();
      } else {
        _coverBytes.value = Uint8List(0);
      }
    }
    setState(() {});
  }

  Future<void> saveSelectedBooks() async {
    setState(() {
      _saveButtonEnabled = false;
    });
    final saveConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.saveToCalibre),
          content: Text(AppLocalizations.of(context)!.saveToCalibreConfirm),
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
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
    if (saveConfirm == null || !saveConfirm) {
      setState(() {
        _saveButtonEnabled = true;
      });
      return;
    }
    final books = getSelectedBooks();
    try {
      final flag = await CalibreHandler.saveBooks(books);
      setState(() {
        _saveButtonEnabled = true;
      });
      if (!mounted) return;
      String content;
      if (flag) {
        content =
            AppLocalizations.of(context)!.saveToCalibreSuccess(books.length);
        content += AppLocalizations.of(context)!.checkLogsForMoreDetails;
      } else {
        content = AppLocalizations.of(context)!.errorDetected;
      }
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.saveToCalibre),
            content: Text(content),
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
      logs.error('Failed to save books to Calibre: $e');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text('Failed to save books to Calibre: $e'),
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
      setState(() {
        _saveButtonEnabled = true;
      });
      return;
    }
  }

  Future<void> updateSelectedBooks() async {
    final logs = Get.find<Logs>();
    setState(() {
      _updateButtonEnabled = false;
    });
    final selectedBooks = getSelectedBooks();
    final total = selectedBooks.length;
    final settings = Get.find<Settings>();
    late final EHentai eHentai;
    try {
      eHentai = EHentai(settings: settings);
    } catch (e) {
      logs.error('Failed to create EHentai: $e');
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.error),
            content: Text('Failed to create EHentai: $e'),
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
      setState(() {
        _updateButtonEnabled = true;
      });
      return;
    }

    bool error = false;

    logs.info('Start to get metadata for ${selectedBooks.length} books');
    final futures = <Future>[];
    for (final book in selectedBooks) {
      futures.add(() async {
        try {
          if (book.metadata.eHentaiUrl.isNotEmpty) {
            await eHentai.identify(
              title: book.metadata.title,
              authors: book.metadata.authors,
              identifiers: book.metadata.identifiers,
              ehentaiUrl: book.metadata.eHentaiUrl,
              id: book.id,
            );
          } else {
            await eHentai.identify(
              title: book.metadata.title,
              authors: book.metadata.authors,
              identifiers: book.metadata.identifiers,
              id: book.id,
            );
          }
        } catch (e) {
          final log = 'Failed to get metadata for ${book.metadata.title}: $e';
          logs.error(log);
          error = true;
          if (eHentai.metadataMap.containsKey(book.id)) {
            // metadata might be incorrect, so remove it
            eHentai.metadataMap.remove(book.id);
          }
        }
      }());
    }
    await Future.wait(futures);
    if (eHentai.metadataMap.isEmpty) {
      setState(() {
        _updateButtonEnabled = true;
      });
      return;
    }
    await BookHandler.updateMetadata(eHentai.metadataMap);

    setState(() {
      for (final book in selectedBooks) {
        if (eHentai.metadataMap.containsKey(book.id)) {
          book.metadata = eHentai.metadataMap[book.id]!;
          if (settings.saveOpf.value) {
            OpfHandler.saveOpf(book);
          }
          _multiSelectedBookId.remove(book.id);
        }
      }
      _updateButtonEnabled = true;
    });
    if (mounted) {
      String title = AppLocalizations.of(context)!.updateMetadata;
      String content = AppLocalizations.of(context)!.updateMetadataSuccess(
        eHentai.metadataMap.length,
        total,
      );

      if (error) {
        title = AppLocalizations.of(context)!.errorDetected;
        content = '$content\n${AppLocalizations.of(context)!.errorDetected}';
      }

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
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
    }
  }

  Future<void> deleteSelectedBooks() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteBooks),
          content: Text(AppLocalizations.of(context)!.deleteBooksConfirm),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(AppLocalizations.of(context)!.yes),
            ),
          ],
        );
      },
    );
    if (shouldDelete != null && shouldDelete) {
      try {
        final selectedBooks = getSelectedBooks();
        final ids = await BookHandler.deleteBooks(selectedBooks);
        if (ids.isEmpty) {
          return;
        }
        if (_selectedBookId != null && ids.contains(_selectedBookId)) {
          setState(() {
            _selectedBookId = null;
          });
        }
        setState(() {
          final booksController = Get.find<BooksController>();
          booksController.removeBooks(ids);
          _multiSelectedBookId.clear();
        });
      } catch (e) {
        final logs = Get.find<Logs>();
        logs.error('Failed to delete books: $e');
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.error),
              content: Text('Failed to delete books: $e'),
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
  }

  Future<void> addBooks() async {
    setState(() {
      _addButtonEnabled = false;
    });
    try {
      final addedBooks = await BookHandler.addBooks(context: context);
      if (addedBooks.isEmpty) {
        setState(() {
          _addButtonEnabled = true;
        });
        return;
      }
      setState(() {
        final booksController = Get.find<BooksController>();
        booksController.addBooks(addedBooks.reversed);
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
      setState(() {
        _addButtonEnabled = true;
      });
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
    setState(() {
      _addButtonEnabled = true;
    });
  }

  PreferredSizeWidget buildAppBar() {
    final theme = Theme.of(context);
    final booksController = Get.find<BooksController>();
    final books = booksController.books;
    return AppBar(
      title: Text(AppLocalizations.of(context)!.books),
      actions: [
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.select_all),
          tooltip: AppLocalizations.of(context)!.selectAll,
          onPressed: () {
            setState(() {
              if (_multiSelectedBookId.length == booksController.length) {
                _multiSelectedBookId.clear();
              } else {
                _multiSelectedBookId.clear();
                // add all book id to _multiSelectedBookId
                for (final book in books) {
                  _multiSelectedBookId.add(book.id);
                }
              }
            });
          },
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.linear_scale),
          tooltip: AppLocalizations.of(context)!.selectRange,
          onPressed: () {
            if (_multiSelectedBookId.isEmpty) return;
            if (_multiSelectedBookId.length == 2) {
              // start and end
              int start = booksController.getIndex(_multiSelectedBookId.first);
              int end = booksController.getIndex(_multiSelectedBookId.last);
              if (start > end) {
                // swap
                final temp = start;
                start = end;
                end = temp;
              }
              if (end - start == 1) {
                setState(() {
                  _multiSelectedBookId.clear();
                });
              } else {
                setState(() {
                  _multiSelectedBookId.clear();
                  // set range
                  for (var i = start; i <= end; i++) {
                    _multiSelectedBookId.add(books[i].id);
                  }
                });
              }
            } else {
              setState(() {
                _multiSelectedBookId.clear();
              });
            }
          },
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.edit),
          tooltip: AppLocalizations.of(context)!.editBooks,
          onPressed: _multiSelectedBookId.isNotEmpty
              ? () async => await editSelectedBooks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.find_in_page),
          tooltip: AppLocalizations.of(context)!.updateMetadata,
          onPressed: _updateButtonEnabled && _multiSelectedBookId.isNotEmpty
              ? () async => await updateSelectedBooks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.save_as),
          tooltip: AppLocalizations.of(context)!.saveToCalibre,
          onPressed: _saveButtonEnabled && _multiSelectedBookId.isNotEmpty
              ? () async => await saveSelectedBooks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.of(context)!.deleteBooks,
          onPressed: _multiSelectedBookId.isNotEmpty
              ? () async => await deleteSelectedBooks()
              : null,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget buildStatusBar() {
    final booksController = Get.find<BooksController>();
    final length = booksController.length;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            height: 0,
            color: Colors.grey,
          ),
          Row(children: [
            if (_multiSelectedBookId.isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!
                    .booksSelected(_multiSelectedBookId.length, length),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ] else ...[
              Text(AppLocalizations.of(context)!.totalBooks(length),
                  style: Theme.of(context).textTheme.labelSmall),
            ]
          ])
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      child: Scaffold(
          appBar: buildAppBar(),
          body: Row(
            children: [
              Flexible(
                flex: 12,
                child: Obx(
                  () => buildBookList(theme.brightness == Brightness.dark),
                ),
              ),
              const VerticalDivider(
                width: 0,
                color: Colors.grey,
                endIndent: 6,
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 5,
                child: buildBookDetail(),
              ),
              const SizedBox(width: 12),
            ],
          ),
          bottomNavigationBar: buildStatusBar(),
          floatingActionButton: FloatingActionButton(
            backgroundColor: _addButtonEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.2),
            onPressed: _addButtonEnabled ? () async => await addBooks() : null,
            child: const Icon(Icons.add),
          )),
    );
  }
}
