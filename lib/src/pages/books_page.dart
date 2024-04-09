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

class BooksPageController extends GetxController {
  final addButtonLock = false.obs;
  final updateButtonLock = false.obs;
  final saveButtonLock = false.obs;
  final selectedNum = 0.obs;
  final hasSelection = false.obs;
  final coverBytes = Uint8List(0).obs;
  final tappedBookId = Rx<int?>(null);

  void lockAddButton() {
    addButtonLock.value = true;
  }

  void unlockAddButton() {
    addButtonLock.value = false;
  }

  void lockUpdateButton() {
    updateButtonLock.value = true;
  }

  void unlockUpdateButton() {
    updateButtonLock.value = false;
  }

  void lockSaveButton() {
    saveButtonLock.value = true;
  }

  void unlockSaveButton() {
    saveButtonLock.value = false;
  }

  void setSelectedNum(int value) {
    if (value < 0) {
      selectedNum.value = 0;
    } else {
      selectedNum.value = value;
    }
  }

  void setHasSelection(bool value) {
    hasSelection.value = value;
  }

  void clearSelection() {
    final books = Get.find<BooksController>().books;
    for (var book in books) {
      book.selected.value = false;
    }
    selectedNum.value = 0;
    hasSelection.value = false;
  }

  void setCoverBytes(Uint8List bytes) {
    coverBytes.value = bytes;
  }

  void setTappedBookId(int? id) {
    tappedBookId.value = id;
  }
}

class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  Widget _buildBooksList(bool isDarkMode) {
    final books = Get.find<BooksController>().books;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.separated(
            itemCount: books.length,
            itemBuilder: (context, index) {
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
                  child: Obx(() {
                    final tapped = books[index].tapped.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 0,
                        ),
                        borderRadius: BorderRadius.circular(6.0),
                        color: tapped
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
                          onTap: () {
                            final controller = Get.find<BooksPageController>();
                            if (tapped) {
                              books[index].tapped.value = false;
                              controller.setTappedBookId(null);
                              controller.setCoverBytes(Uint8List(0));
                            } else {
                              final lastTappedId =
                                  controller.tappedBookId.value;
                              final lastTappedIndex = books.indexWhere(
                                  (book) => book.id == lastTappedId);
                              if (lastTappedIndex != -1) {
                                books[lastTappedIndex].tapped.value = false;
                              }
                              books[index].tapped.value = true;
                              controller.setTappedBookId(books[index].id);
                              final cover = File(books[index].coverPath);
                              if (cover.existsSync()) {
                                controller
                                    .setCoverBytes(cover.readAsBytesSync());
                              } else {
                                controller.setCoverBytes(Uint8List(0));
                              }
                            }
                          },
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(children: [
                                Obx(
                                  () => Checkbox(
                                    value: books[index].selected.value,
                                    onChanged: (value) {
                                      final controller =
                                          Get.find<BooksPageController>();
                                      if (value!) {
                                        books[index].selected.value = true;
                                        controller.setSelectedNum(
                                            controller.selectedNum.value + 1);
                                        controller.setHasSelection(true);
                                      } else {
                                        books[index].selected.value = false;
                                        controller.setSelectedNum(
                                            controller.selectedNum.value - 1);
                                        controller.setHasSelection(
                                            controller.selectedNum.value != 0);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
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
                    );
                  }));
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

  Widget _buildBookDetail(BuildContext context) {
    String title = '';
    String eHentaiUrl = '';
    String? authors;
    String? publisher;
    String? tags;
    String? languages;
    double? rating;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: GetX(
          builder: (BooksPageController controller) {
            final tappedBookId = controller.tappedBookId.value;
            if (tappedBookId != null) {
              final booksController = Get.find<BooksController>();
              final index = booksController.getIndex(tappedBookId);
              final book = booksController.getBook(index);
              title = book.metadata.title;
              eHentaiUrl = book.metadata.eHentaiUrl;
              authors = book.metadata.authors?.join(',');
              publisher = book.metadata.publisher;
              tags = book.metadata.tags?.join(', ');
              languages = book.metadata.languages?.join(', ');
              rating = book.metadata.rating;
            }
            final coverBytes = controller.coverBytes.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                if (tappedBookId != null) ...[
                  coverBytes.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [Image.memory(coverBytes), const Divider()],
                        ),
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
                  if (authors != null && authors!.isNotEmpty)
                    Text(
                      '${AppLocalizations.of(context)!.authors}: $authors',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (publisher != null && publisher!.isNotEmpty)
                    Text(
                      '${AppLocalizations.of(context)!.publisher}: $publisher',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (tags != null && tags!.isNotEmpty)
                    Text(
                      '${AppLocalizations.of(context)!.tags}: $tags',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  if (languages != null && languages!.isNotEmpty)
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
            );
          },
        ),
      ),
    );
  }

  List<Book> _getSelectedBooks() {
    final books = Get.find<BooksController>().books;
    final selectedBooks = <Book>[];
    for (final book in books) {
      if (book.selected.value) {
        selectedBooks.add(book);
      }
    }
    return selectedBooks;
  }

  Future<void> _editSelectedBooks(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return const EditDialog();
      },
    );
    final booksController = Get.find<BooksController>();
    booksController.refreshBooks();
    final controller = Get.find<BooksPageController>();
    final tapppedBookId = controller.tappedBookId.value;
    if (tapppedBookId != null) {
      final index = booksController.getIndex(tapppedBookId);
      final book = Get.find<BooksController>().getBook(index);
      final cover = File(book.coverPath);
      if (await cover.exists()) {
        controller.setCoverBytes(await cover.readAsBytes());
      } else {
        controller.setCoverBytes(Uint8List(0));
      }
    }
  }

  Future<void> _saveSelectedBooks(BuildContext context) async {
    final controller = Get.find<BooksPageController>();
    controller.lockSaveButton();
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
      controller.unlockSaveButton();
      return;
    }
    final books = _getSelectedBooks();
    try {
      final flag = await CalibreHandler.saveBooks(books);
      controller.unlockSaveButton();
      if (!context.mounted) return;
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
      if (!context.mounted) return;
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
      controller.unlockSaveButton();
      return;
    }
  }

  Future<void> _updateSelectedBooks(BuildContext context) async {
    final controller = Get.find<BooksPageController>();
    controller.lockUpdateButton();
    final logs = Get.find<Logs>();
    final selectedBooks = _getSelectedBooks();
    final total = selectedBooks.length;
    final settings = Get.find<Settings>();
    late final EHentai eHentai;
    try {
      eHentai = EHentai(settings: settings);
    } catch (e) {
      logs.error('Failed to create EHentai: $e');
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
      controller.unlockUpdateButton();
      return;
    }

    bool error = false;

    if (eHentai.chineseEHentai && eHentai.transDbPath.isNotEmpty) {
      try {
        await eHentai.initTransDb(logs);
      } catch (e) {
        logs.error('Failed to init translation database: $e');
        eHentai.transDb = null;
        error = true;
      }
    }

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
              eHentaiUrl: book.metadata.eHentaiUrl,
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
    await eHentai.translateMetadata();
    await eHentai.closeTransDb(logs);
    if (eHentai.metadataMap.isEmpty) {
      controller.unlockUpdateButton();
      return;
    }
    await BookHandler.updateMetadata(eHentai.metadataMap);

    int succeeded = 0;
    for (final book in selectedBooks) {
      if (eHentai.metadataMap.containsKey(book.id)) {
        succeeded++;
        book.metadata = eHentai.metadataMap[book.id]!;
        if (settings.saveOpf.value) {
          OpfHandler.saveOpf(book);
        }
        book.selected.value = false;
      }
    }
    final booksController = Get.find<BooksController>();
    booksController.refreshBooks();
    controller.unlockUpdateButton();
    controller.setSelectedNum(selectedBooks.length - succeeded);
    controller.setHasSelection(controller.selectedNum.value != 0);

    if (context.mounted) {
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

  Future<void> _deleteSelectedBooks(BuildContext context) async {
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
      final controller = Get.find<BooksPageController>();
      try {
        final selectedBooks = _getSelectedBooks();
        final ids = await BookHandler.deleteBooks(selectedBooks);
        if (ids.isEmpty) {
          return;
        }
        final tapppedBookId = controller.tappedBookId.value;
        if (tapppedBookId != null && ids.contains(tapppedBookId)) {
          controller.setTappedBookId(null);
        }
        final booksController = Get.find<BooksController>();
        booksController.removeBooks(ids);
        controller.clearSelection();
      } catch (e) {
        final logs = Get.find<Logs>();
        logs.error('Failed to delete books: $e');
        if (!context.mounted) return;
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

  Future<void> _addBooks(BuildContext context) async {
    final controller = Get.find<BooksPageController>();
    controller.lockAddButton();
    try {
      final addedBooks = await BookHandler.addBooks(context: context);
      if (addedBooks.isEmpty) {
        controller.unlockAddButton();
        return;
      }
      final booksController = Get.find<BooksController>();
      booksController.addBooks(addedBooks.reversed);
      if (!context.mounted) return;
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
      controller.unlockAddButton();
      if (!context.mounted) return;
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
    controller.unlockAddButton();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final booksController = Get.find<BooksController>();
    final books = booksController.books;
    final controller = Get.find<BooksPageController>();
    return AppBar(
      title: Text(AppLocalizations.of(context)!.books),
      actions: [
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.select_all),
          tooltip: AppLocalizations.of(context)!.selectAll,
          onPressed: () {
            final hasBookSelected = books.any((book) => book.selected.value);
            if (hasBookSelected) {
              controller.clearSelection();
            } else {
              for (final book in books) {
                book.selected.value = true;
              }
              controller.setSelectedNum(books.length);
              controller.setHasSelection(true);
            }
          },
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.linear_scale),
          tooltip: AppLocalizations.of(context)!.selectRange,
          onPressed: () {
            if (controller.selectedNum.value == 0) return;
            if (controller.selectedNum.value == 2) {
              final selectedBooks = _getSelectedBooks();
              final first = selectedBooks.first;
              final last = selectedBooks.last;
              final firstIndex = books.indexWhere((book) => book == first);
              final lastIndex = books.indexWhere((book) => book == last);
              int selectedNum = 0;
              for (var i = 0; i < books.length; i++) {
                if (i >= firstIndex && i <= lastIndex) {
                  books[i].selected.value = true;
                  selectedNum++;
                } else {
                  books[i].selected.value = false;
                }
              }
              controller.setSelectedNum(selectedNum);
              controller.setHasSelection(true);
            } else {
              controller.clearSelection();
            }
          },
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.edit),
            tooltip: AppLocalizations.of(context)!.editBooks,
            onPressed: controller.hasSelection.value
                ? () async => await _editSelectedBooks(context)
                : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.find_in_page),
            tooltip: AppLocalizations.of(context)!.updateMetadata,
            onPressed: controller.hasSelection.value &&
                    !controller.updateButtonLock.value
                ? () async => await _updateSelectedBooks(context)
                : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.save_as),
            tooltip: AppLocalizations.of(context)!.saveToCalibre,
            onPressed: controller.hasSelection.value &&
                    !controller.saveButtonLock.value
                ? () async => await _saveSelectedBooks(context)
                : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.delete),
            tooltip: AppLocalizations.of(context)!.deleteBooks,
            onPressed: controller.hasSelection.value
                ? () async => await _deleteSelectedBooks(context)
                : null,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final controller = Get.find<BooksPageController>();
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
            Obx(() {
              final booksController = Get.find<BooksController>();
              final length = booksController.books.length;
              if (controller.selectedNum.value != 0) {
                return Text(
                  AppLocalizations.of(context)!
                      .booksSelected(controller.selectedNum, length),
                  style: Theme.of(context).textTheme.labelSmall,
                );
              } else {
                return Text(AppLocalizations.of(context)!.totalBooks(length),
                    style: Theme.of(context).textTheme.labelSmall);
              }
            })
          ])
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BooksPageController());
    return AppPage(
      child: Scaffold(
          appBar: _buildAppBar(context),
          body: Row(
            children: [
              Flexible(
                flex: 12,
                child: Obx(
                  () => _buildBooksList(theme.brightness == Brightness.dark),
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
                child: _buildBookDetail(context),
              ),
              const SizedBox(width: 12),
            ],
          ),
          bottomNavigationBar: _buildStatusBar(context),
          floatingActionButton: Obx(() => FloatingActionButton(
                backgroundColor: !controller.addButtonLock.value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.2),
                onPressed: !controller.addButtonLock.value
                    ? () async => await _addBooks(context)
                    : null,
                child: const Icon(Icons.add),
              ))),
    );
  }
}
