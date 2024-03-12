import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/database.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/handler.dart';
import 'package:eh_tagger/src/calibre/opf.dart';
import 'package:eh_tagger/src/ehentai/archive.dart';
import 'package:eh_tagger/src/ehentai/constants.dart';
import 'package:eh_tagger/src/ehentai/ehentai.dart';
import 'package:eh_tagger/src/pages/widgets/drag_target.dart';
import 'package:eh_tagger/src/pages/widgets/edit_dialog.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item/dialog_input_urls.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' hide context;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  bool _addButtonEnabled = true;
  bool _updateButtonEnabled = true;
  bool _saveButtonEnabled = true;
  final _books = <Book>[];
  int? _selectedBookId;
  final _multiSelectedBookId = <int>{};
  final _coverBytes = Uint8List(0).obs;

  @override
  void initState() {
    super.initState();
    final settings = Get.find<Settings>();
    if (!settings.dbInitialized) {
      _addButtonEnabled = false;
      _updateButtonEnabled = false;
      _saveButtonEnabled = false;
    }
    Future.microtask(() async {
      final books = await AppDatabase().queryBooks();
      if (books.isNotEmpty) {
        setState(() {
          _books.addAll(books);
        });
      }
    });
  }

  int _getIndex(int bookId) {
    return _books.indexWhere((book) => book.id == bookId);
  }

  void updateBooks() {
    setState(() {});
  }

  Widget buildBookList(bool isDarkMode) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.separated(
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final bookId = _books[index].id;
              final title = _books[index].metadata.title;
              final authors = _books[index].metadata.authors?.join(',');
              final publisher = _books[index].metadata.publisher;
              final tags = _books[index].metadata.tags?.join(', ');
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
                            final cover = File(_books[index].coverPath);
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
        IgnorePointer(
          child: Center(
            child: DragTargetWidget(books: _books, onBooksChanged: updateBooks),
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

    if (_selectedBookId != null) {
      final index = _getIndex(_selectedBookId!);
      title = _books[index].metadata.title;
      eHentaiUrl = _books[index].metadata.eHentaiUrl;
      authors = _books[index].metadata.authors?.join(',');
      publisher = _books[index].metadata.publisher;
      tags = _books[index].metadata.tags?.join(', ');
      languages = _books[index].metadata.languages?.join(', ');
      rating = _books[index].metadata.rating;
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
    return _books.where((book) => ids.contains(book.id)).toList();
  }

  Future<void> downloadBooks() async {
    final urls = await showDialog<List<String>>(
      context: context,
      builder: (context) => const DialogInputUrls(),
    );
    if (urls == null || urls.isEmpty) {
      return;
    }

    final settings = Get.find<Settings>();
    final logs = Get.find<Logs>();
    final archiveDownloadHandler = ArchiveDownloadHandler(
      urls: urls,
      settings: settings,
      logs: logs,
    );
    final archives = await archiveDownloadHandler.getArchives();
    if (archives.isEmpty) return;

    final downloader = FileDownloader();
    final tasks = <DownloadTask>[];

    for (final archive in archives) {
      if (archive.archiveUrl.isEmpty) {
        logs.error('Archive url is empty: ${archive.name}');
        continue;
      }
      tasks.add(DownloadTask(
        displayName: archive.name,
        url: '${archive.archiveUrl}$downloadStartSuffix',
        metaData: archive.galleryUrl,
        directory: downloadTemporaryDirName,
        baseDirectory: BaseDirectory.temporary,
        updates: Updates.statusAndProgress,
        allowPause: false,
      ));
    }
    if (settings.useProxy.value && settings.proxyLink.value.isNotEmpty) {
      try {
        final host = settings.proxyLink.value.split(':')[0];
        final port = int.parse(settings.proxyLink.value.split(':')[1]);
        await downloader.configure(globalConfig: [('proxy', (host, port))]);
      } catch (e) {
        logs.error('Failed to configure proxy: $e');
        return;
      }
    } else {
      await downloader.configure(globalConfig: []);
    }
    final progress = <String, int>{};
    final results = await downloader.downloadBatch(
      tasks,
      taskProgressCallback: (update) {
        final progressPercentage = (update.progress * 100).toInt();
        if (!progress.containsKey(update.task.taskId)) {
          progress[update.task.taskId] = 0;
        }
        if (progressPercentage - progress[update.task.taskId]! >
            downloadThreshold) {
          progress[update.task.taskId] = progressPercentage;
          logs.info(
            'Downloading ${update.task.displayName}: $progressPercentage%, speed: ${update.networkSpeedAsString}',
          );
        }
      },
      batchProgressCallback: (succeeded, failed) {
        if (succeeded == 0 && failed == 0) {
          logs.info('Start to download ${tasks.length} archives');
        }
      },
    );
    logs.info(
        'Downloaded ${results.succeeded.length}/${tasks.length} archives');

    final downloadDir = Directory(join(
      AppStorage.libraryPath,
      downloadDirName,
    ));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    final tempDir = await getTemporaryDirectory();
    final platformFiles = <PlatformFile>[];
    final succeedUrls = <String>[];
    for (final task in results.succeeded) {
      final file = File(join(
        tempDir.path,
        downloadTemporaryDirName,
        task.filename,
      ));
      if (!await file.exists()) {
        logs.error('File not found: ${file.path}');
        continue;
      }
      // move to downloadDir
      final newFile = File(join(
        downloadDir.path,
        task.displayName,
      ));
      await file.copy(newFile.path);
      await file.delete();
      if (settings.addBooksAfterDownload.value) {
        platformFiles.add(PlatformFile(
          name: task.displayName,
          path: newFile.path,
          size: await newFile.length(),
          bytes: await newFile.readAsBytes(),
        ));
        succeedUrls.add(task.metaData);
      }
    }

    if (settings.addBooksAfterDownload.value) {
      final books = await BookHandler.addBooks(
        platformFiles: platformFiles,
        urls: succeedUrls,
      );
      if (books.isNotEmpty) {
        final reversedBooks = books.reversed.toList();
        _books.insertAll(0, reversedBooks);
        if (settings.fetchMetadataAfterDownload.value) {
          final ids = reversedBooks.map((book) => book.id);
          await updateSelectedBooks(ids, false);
        }
      }
      setState(() {});
    }
  }

  Future<void> editSelectedBooks() async {
    if (_multiSelectedBookId.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.editBooks),
            content: Text(AppLocalizations.of(context)!.selectedBooksEmpty),
            actions: [
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
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return EditDialog(
          books: getSelectedBooks(),
        );
      },
    );
    if (_selectedBookId != null) {
      final index = _getIndex(_selectedBookId!);
      final cover = File(_books[index].coverPath);
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
    if (_multiSelectedBookId.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.saveToCalibre),
            content: Text(AppLocalizations.of(context)!.selectedBooksEmpty),
            actions: [
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
      setState(() {
        _saveButtonEnabled = true;
      });
      return;
    }
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

  Future<void> updateSelectedBooks(Iterable<int> ids,
      [bool notify = true]) async {
    setState(() {
      _updateButtonEnabled = false;
    });
    if (ids.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.updateMetadata),
            content: Text(AppLocalizations.of(context)!.selectedBooksEmpty),
            actions: [
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
      setState(() {
        _updateButtonEnabled = true;
      });
      return;
    }
    final books = _books.where((book) => ids.contains(book.id)).toList();
    final total = books.length;
    final settings = Get.find<Settings>();
    late final EHentai eHentai;
    try {
      eHentai = EHentai(settings: settings);
    } catch (e) {
      final logs = Get.find<Logs>();
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

    final logs = Get.find<Logs>();
    logs.info('Start to get metadata for ${books.length} books');
    final futures = <Future>[];
    for (final book in books) {
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
      for (final book in _books) {
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
    if (mounted && notify) {
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
    if (_multiSelectedBookId.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteBooks),
            content: Text(AppLocalizations.of(context)!.selectedBooksEmpty),
            actions: [
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
      return;
    }
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
    if (shouldDelete != null && shouldDelete) {
      try {
        final books = getSelectedBooks();
        final ids = await BookHandler.deleteBooks(books);
        if (ids.isEmpty) {
          return;
        }
        if (_selectedBookId != null && ids.contains(_selectedBookId)) {
          setState(() {
            _selectedBookId = null;
          });
        }
        setState(() {
          _books.removeWhere((book) => ids.contains(book.id));
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
        _books.insertAll(0, addedBooks.reversed);
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
    final settings = Get.find<Settings>();
    return AppBar(
      title: Text(AppLocalizations.of(context)!.books),
      actions: [
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.select_all),
          tooltip: AppLocalizations.of(context)!.selectAll,
          onPressed: () {
            setState(() {
              if (_multiSelectedBookId.length == _books.length) {
                _multiSelectedBookId.clear();
              } else {
                _multiSelectedBookId.clear();
                // add all book id to _multiSelectedBookId
                for (final book in _books) {
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
              int start = _getIndex(_multiSelectedBookId.first);
              int end = _getIndex(_multiSelectedBookId.last);
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
                    _multiSelectedBookId.add(_books[i].id);
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
          icon: const Icon(Icons.download),
          tooltip: AppLocalizations.of(context)!.downloadBooks,
          onPressed:
              settings.dbInitialized ? () async => await downloadBooks() : null,
        ),
        // openDownloadDir
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.folder_open),
          tooltip: AppLocalizations.of(context)!.openDownloadDir,
          onPressed: () async {
            final downloadDir = Directory(AppStorage.downloadPath);
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            final uri = Uri.file(downloadDir.path);
            final logs = Get.find<Logs>();
            try {
              if (!await launchUrl(uri)) {
                logs.error('Failed to open download dir: ${uri.path}');
              }
            } catch (e) {
              logs.error('Failed to open download dir: $e');
            }
          },
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.edit),
          tooltip: AppLocalizations.of(context)!.editBooks,
          onPressed: settings.dbInitialized
              ? () async => await editSelectedBooks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.find_in_page),
          tooltip: AppLocalizations.of(context)!.updateMetadata,
          onPressed: _updateButtonEnabled
              ? () async => await updateSelectedBooks(_multiSelectedBookId)
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.save_as),
          tooltip: AppLocalizations.of(context)!.saveToCalibre,
          onPressed:
              _saveButtonEnabled ? () async => await saveSelectedBooks() : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.of(context)!.deleteBooks,
          onPressed: settings.dbInitialized
              ? () async => await deleteSelectedBooks()
              : null,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget buildStatusBar() {
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
                    .booksSelected(_multiSelectedBookId.length, _books.length),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ] else ...[
              Text(AppLocalizations.of(context)!.totalBooks(_books.length),
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
                child: buildBookList(theme.brightness == Brightness.dark),
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
