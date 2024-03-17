import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eh_tagger/src/app/books.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/opf.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:eh_tagger/src/downloader/progress_monitor.dart';
import 'package:eh_tagger/src/downloader/task.dart';
import 'package:eh_tagger/src/ehentai/archive.dart';
import 'package:eh_tagger/src/ehentai/ehentai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

extension TaskHandler on Downloader {
  Future<List<EHArchive>> _getArchives(List<String> urls) async {
    final futures = <Future>[];
    final archives = <EHArchive>[];
    for (final url in urls) {
      futures.add(() async {
        try {
          archives.add(await getArchiveData(url));
        } catch (e) {
          logs.error('Failed to get archive url for $url: $e');
        }
      }());
    }
    await Future.wait(futures);
    return archives;
  }

  Future<List<int>> addtasks(List<String> urls) async {
    final archives = await _getArchives(urls);
    final ids = <int>[];
    for (final archive in archives) {
      final newTask = DownloadTask.newTask(
        name: archive.name,
        path: join(AppStorage.downloadPath, archive.name),
        size: archive.size,
        eHentaiUrl: archive.galleryUrl,
        downloadUrl: archive.archiveUrl,
      );
      final id = await taskDao.insertTask(newTask);
      newTask.id = id;
      tasks.insert(0, newTask);
      ids.add(id);
    }
    return ids;
  }

  Future<void> startTasks(Iterable<int> ids) async {
    final indexes =
        ids.map((id) => tasks.indexWhere((task) => task.id == id)).toList();
    final futures = <Future>[];
    for (final index in indexes) {
      futures.add(_startTask(index));
    }
    await Future.wait(futures);
  }

  Future<void> _startTask(int index) async {
    final task = tasks[index];

    if (task.status.value != TaskStatus.paused &&
        task.status.value != TaskStatus.canceled) {
      return;
    }

    // check if task is already running
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        logs.info('Download already running: ${task.name}');
        return;
      }
    }
    cancelTokens[task.id] = CancelToken();

    Map<String, dynamic>? headers;
    int bytes = 0;
    String range = '';
    bool isResume = false;
    // check if file exists
    final file = File(task.path);
    if (await file.exists()) {
      // try to resume download
      bytes = await file.length();
      if (bytes < task.size) {
        isResume = true;
        range = 'bytes=$bytes-';
      } else {
        logs.info('File already exists: ${task.path}');
        await _updateTaskStatus(
          index: index,
          status: TaskStatus.completed,
          writeToDb: true,
        );
        return;
      }
    }

    // start download
    if (isResume) {
      headers = {'Range': range};
      logs.info('Resume download: ${task.name}, range: $bytes-${task.size}');
    } else {
      logs.info('Start download: ${task.name}');
    }
    final options = Options(
      headers: headers,
      preserveHeaderCase: true,
    );
    await _updateTaskStatus(
        index: index, status: TaskStatus.running, writeToDb: true);
    final monitor = TaskMonitor()..receivedBytes = bytes;
    monitor.start();
    await dio.download(
      task.downloadUrl,
      task.path,
      shouldAppendFile: true,
      deleteOnError: false,
      cancelToken: cancelTokens[task.id]!,
      onReceiveProgress: (received, total) {
        final receivedBytes = bytes + received;
        final progress = receivedBytes / task.size;
        _updateTaskProgress(index: index, progress: progress);
        monitor.updateReceivedBytes(receivedBytes);
        _updateTaskSpeed(index: index, speed: monitor.speed);
      },
      options: options,
    ).then((response) {
      logs.info('Download completed: ${task.name}');
      monitor.stop();
      _updateTaskStatus(
          index: index, status: TaskStatus.completed, writeToDb: true);
      _updateTaskProgress(index: index, progress: 1, writeToDb: true);
      _updateTaskSpeed(index: index, speed: '');
      _onTaskComplete(task);
    }).catchError((e) {
      monitor.stop();
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          // ignore
        } else if (e.response?.statusCode == HttpStatus.gone ||
            e.response?.statusCode == HttpStatus.ok) {
          logs.error('Download failed: ${task.name}: ${e.response?.data}');
          _updateTaskStatus(
              index: index, status: TaskStatus.failed, writeToDb: true);
          _updateTaskProgress(index: index, progress: 0, writeToDb: true);
          _updateTaskSpeed(index: index, speed: '');
        } else {
          logs.error('Download failed: ${task.name}: $e');
          _updateTaskStatus(
              index: index, status: TaskStatus.failed, writeToDb: true);
          _updateTaskProgress(index: index, progress: 0, writeToDb: true);
          _updateTaskSpeed(index: index, speed: '');
        }
      } else {
        logs.error('Download failed: ${task.name}: $e');
        _updateTaskStatus(
            index: index, status: TaskStatus.failed, writeToDb: true);
        _updateTaskProgress(index: index, progress: 0, writeToDb: true);
        _updateTaskSpeed(index: index, speed: '');
      }
    });
  }

  Future<void> pauseTasks(Iterable<int> ids) async {
    final indexes =
        ids.map((id) => tasks.indexWhere((task) => task.id == id)).toList();
    for (final index in indexes) {
      await _pauseTask(index);
    }
  }

  Future<void> _pauseTask(int index) async {
    final task = tasks[index];
    if (task.status.value != TaskStatus.running) {
      return;
    }
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        cancelTokens[task.id]!.cancel();
        logs.info('Download paused: ${task.name}');
        final progress = task.progress.value;
        await _updateTaskStatus(
            index: index, status: TaskStatus.paused, writeToDb: true);
        await _updateTaskProgress(
            index: index, progress: progress, writeToDb: true);
        _updateTaskSpeed(index: index, speed: '');
      }
    }
  }

  Future<void> cancelTasks(Iterable<int> ids) async {
    final indexes =
        ids.map((id) => tasks.indexWhere((task) => task.id == id)).toList();
    for (final index in indexes) {
      await _cancelTask(index);
    }
  }

  Future<void> _cancelTask(int index) async {
    final task = tasks[index];
    if (task.status.value == TaskStatus.completed) {
      return;
    }
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        cancelTokens[task.id]!.cancel();
      }
      cancelTokens.remove(task.id);
    }
    logs.info('Download canceled: ${task.name}');
    await _updateTaskStatus(
        index: index, status: TaskStatus.canceled, writeToDb: true);
    await _updateTaskProgress(index: index, progress: 0, writeToDb: true);
    _updateTaskSpeed(index: index, speed: '');
    final file = File(task.path);
    if (await file.exists()) {
      logs.info('Delete file: ${task.path}');
      await file.delete();
    }
  }

  Future<void> deleteTasks(Iterable<int> ids) async {
    final indexes =
        ids.map((id) => tasks.indexWhere((task) => task.id == id)).toList();
    for (final index in indexes) {
      await _deleteTask(index);
    }
  }

  Future<void> _deleteTask(int index) async {
    final task = tasks[index];
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        cancelTokens[task.id]!.cancel();
      }
      cancelTokens.remove(task.id);
    }
    final file = File(task.path);
    logs.info('Remove download task: ${task.name}');
    await taskDao.deleteTask(id: task.id);
    tasks.removeAt(index);
    if (await file.exists()) {
      logs.info('Delete file: ${task.path}');
      await file.delete();
    }
  }

  Future<void> _onTaskComplete(DownloadTask task) async {
    final file = File(task.path);
    if (!await file.exists()) {
      logs.error('File not found: ${task.path}');
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length != task.size) {
      logs.error('File size not match: ${task.path}');
      return;
    }
    // if addBooksAfterDownload or fetchMetadataAfterDownload is set
    late final PlatformFile platformFile;
    late final String url;
    final settings = Get.find<Settings>();
    if (settings.addBooksAfterDownload.value) {
      platformFile = PlatformFile(
        name: task.name,
        path: task.path,
        size: await file.length(),
        bytes: bytes,
      );
      url = task.eHentaiUrl;
    }
    if (settings.addBooksAfterDownload.value) {
      final books = await BookHandler.addBooks(
        platformFile: platformFile,
        url: url,
      );
      if (books.isNotEmpty) {
        final book = books.first; // only one book
        final booksController = Get.find<BooksController>();

        if (settings.fetchMetadataAfterDownload.value) {
          late final EHentai eHentai;
          try {
            eHentai = EHentai(settings: settings);
          } catch (e) {
            logs.error('Failed to create EHentai: $e');
            return;
          }
          if (eHentai.chineseEHentai && eHentai.transDbPath.isNotEmpty) {
            try {
              await eHentai.initTransDb(logs);
            } catch (e) {
              logs.error('Failed to init translation database: $e');
              eHentai.transDb = null;
            }
          }
          try {
            logs.info('Start to get metadata for 1 books');
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
            await eHentai.translateMetadata();
            await eHentai.closeTransDb(logs);
            await BookHandler.updateMetadata(eHentai.metadataMap);
            book.metadata = eHentai.metadataMap[book.id]!;
            if (settings.saveOpf.value) {
              OpfHandler.saveOpf(book);
            }
          } catch (e) {
            final log = 'Failed to get metadata for ${book.metadata.title}: $e';
            logs.error(log);
          }
        }
        booksController.addBook(book);
      }
    }
  }

  Future<void> _updateTaskStatus({
    required int index,
    required TaskStatus status,
    bool? writeToDb,
  }) async {
    tasks[index].status.value = status;
    if (writeToDb != null && writeToDb) {
      await taskDao.updateStatus(id: tasks[index].id, status: status.index);
    }
  }

  Future<void> _updateTaskProgress({
    required int index,
    required double progress,
    bool? writeToDb,
  }) async {
    tasks[index].progress.value = progress;
    if (writeToDb != null && writeToDb) {
      await taskDao.updateProgress(id: tasks[index].id, progress: progress);
    }
  }

  void _updateTaskSpeed({
    required int index,
    required String speed,
  }) {
    tasks[index].speed.value = speed;
  }
}
