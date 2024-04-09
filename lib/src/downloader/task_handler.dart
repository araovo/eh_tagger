import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eh_tagger/src/app/books.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/calibre/opf.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:eh_tagger/src/downloader/task_monitor.dart';
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
          logs.error('Failed to get archive from $url: $e');
          failedUrls.add(url);
        }
      }());
    }
    await Future.wait(futures);
    return archives;
  }

  Future<List<DownloadTask>> addtasks(List<String> urls) async {
    final archives = await _getArchives(urls);
    final tasksToAdd = <DownloadTask>[];
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
      tasksToAdd.insert(0, newTask);
    }
    return tasksToAdd;
  }

  Future<void> startTasks(List<DownloadTask> tasks) async {
    final futures = <Future>[];
    for (final task in tasks) {
      futures.add(_startTask(task));
    }
    await Future.wait(futures);
  }

  Future<void> _startTask(DownloadTask task) async {
    if (task.status.value != TaskStatus.paused &&
        task.status.value != TaskStatus.canceled &&
        task.status.value != TaskStatus.failed) {
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
          task: task,
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
        task: task, status: TaskStatus.running, writeToDb: true);
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
        _updateTaskProgress(task: task, progress: progress);
        monitor.updateReceivedBytes(receivedBytes);
        _updateTaskSpeed(task: task, speed: monitor.speed);
      },
      options: options,
    ).then((response) async {
      logs.info('Download completed: ${task.name}');
      monitor.stop();
      await _updateTaskStatus(
          task: task, status: TaskStatus.completed, writeToDb: true);
      await _updateTaskProgress(task: task, progress: 1, writeToDb: true);
      _updateTaskSpeed(task: task, speed: '');
      await _onTaskComplete(task);
    }).catchError((e) async {
      monitor.stop();
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          // ignore
        } else if (e.response?.statusCode == HttpStatus.gone ||
            e.response?.statusCode == HttpStatus.ok) {
          await _handleError(task, e.response?.data);
        } else {
          await _handleError(task, e);
        }
      } else {
        await _handleError(task, e);
      }
    });
  }

  Future<void> _handleError(DownloadTask task, dynamic e) async {
    logs.error('Download failed: ${task.name}: $e');
    await _updateTaskStatus(
        task: task, status: TaskStatus.failed, writeToDb: true);
    await _updateTaskProgress(task: task, progress: 0, writeToDb: true);
    _updateTaskSpeed(task: task, speed: '');
  }

  Future<void> pauseTasks(List<DownloadTask> tasks) async {
    for (final task in tasks) {
      await _pauseTask(task);
    }
  }

  Future<void> _pauseTask(DownloadTask task) async {
    if (task.status.value != TaskStatus.running) {
      return;
    }
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        cancelTokens[task.id]!.cancel();
        logs.info('Download paused: ${task.name}');
        final progress = task.progress.value;
        await _updateTaskStatus(
            task: task, status: TaskStatus.paused, writeToDb: true);
        await _updateTaskProgress(
            task: task, progress: progress, writeToDb: true);
        _updateTaskSpeed(task: task, speed: '');
      }
    }
  }

  Future<void> cancelTasks(List<DownloadTask> tasks) async {
    for (final task in tasks) {
      await _cancelTask(task);
    }
  }

  Future<void> _cancelTask(DownloadTask task) async {
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
        task: task, status: TaskStatus.canceled, writeToDb: true);
    await _updateTaskProgress(task: task, progress: 0, writeToDb: true);
    _updateTaskSpeed(task: task, speed: '');
    final file = File(task.path);
    if (await file.exists()) {
      logs.info('Delete file: ${task.path}');
      await file.delete();
    }
  }

  Future<void> deleteTasks(List<DownloadTask> tasks) async {
    for (final task in tasks) {
      await _deleteTask(task);
    }
  }

  Future<void> _deleteTask(DownloadTask task) async {
    if (cancelTokens.containsKey(task.id)) {
      if (!cancelTokens[task.id]!.isCancelled) {
        cancelTokens[task.id]!.cancel();
      }
      cancelTokens.remove(task.id);
    }
    final file = File(task.path);
    logs.info('Remove download task: ${task.name}');
    await taskDao.deleteTask(id: task.id);
    tasks.remove(task);
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
    required DownloadTask task,
    required TaskStatus status,
    bool? writeToDb,
  }) async {
    task.status.value = status;
    if (writeToDb != null && writeToDb) {
      await taskDao.updateStatus(id: task.id, status: status.index);
    }
  }

  Future<void> _updateTaskProgress({
    required DownloadTask task,
    required double progress,
    bool? writeToDb,
  }) async {
    task.progress.value = progress;
    if (writeToDb != null && writeToDb) {
      await taskDao.updateProgress(id: task.id, progress: progress);
    }
  }

  void _updateTaskSpeed({
    required DownloadTask task,
    required String speed,
  }) {
    task.speed.value = speed;
  }
}
