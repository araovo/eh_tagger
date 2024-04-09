import 'dart:io';

import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:eh_tagger/src/downloader/task.dart';
import 'package:eh_tagger/src/downloader/task_handler.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:eh_tagger/src/pages/widgets/dialog_input_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadPageController extends GetxController {
  final buttonsLock = false.obs;
  int selectedNum = 0;
  final hasSelection = false.obs;

  void lock() {
    buttonsLock.value = true;
  }

  void unlock() {
    buttonsLock.value = false;
  }

  void setHasSelection(bool value) {
    hasSelection.value = value;
  }

  void clearSelection() {
    final downloader = Get.find<Downloader>();
    for (var task in downloader.tasks) {
      task.selected.value = false;
    }
    selectedNum = 0;
    hasSelection.value = false;
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  Widget _buildTaskList(bool isDarkMode) {
    Color getStatusColor(TaskStatus status) {
      switch (status) {
        case TaskStatus.running:
          return taskRunningColor;
        case TaskStatus.paused:
          return taskPausedColor;
        case TaskStatus.failed || TaskStatus.canceled:
          return taskFailedColor;
        case TaskStatus.completed:
          return taskCompletedColor;
        default:
          return Colors.grey;
      }
    }

    Color? getStatusBackgroundColor(TaskStatus status) {
      switch (status) {
        case TaskStatus.failed || TaskStatus.canceled:
          return taskFailedColor;
        default:
          return null;
      }
    }

    String formatSize(double size) {
      var unit = 0;
      while (size >= 1024 && unit < sizeUnits.length - 1) {
        size /= 1024;
        unit++;
      }
      return '${size.toStringAsFixed(2)} ${sizeUnits[unit]}';
    }

    final tasks = Get.find<Downloader>().tasks;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Obx(
        () => ListView.separated(
          itemCount: tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final task = tasks[index];
            final name = task.name;
            final status = task.status;
            final progress = task.progress;
            final speed = task.speed;
            return ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 0,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                  color: isDarkMode ? Colors.grey[850]! : Colors.grey[350]!,
                ),
                child: Material(
                    color: Colors.transparent,
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(
                          () => LinearProgressIndicator(
                            value: progress.value,
                            valueColor: AlwaysStoppedAnimation(
                              getStatusColor(status.value),
                            ),
                            backgroundColor:
                                getStatusBackgroundColor(status.value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Obx(
                                () => Checkbox(
                                  value: task.selected.value,
                                  onChanged: (value) {
                                    final controller =
                                        Get.find<DownloadPageController>();
                                    if (value!) {
                                      task.selected.value = true;
                                      controller.setHasSelection(true);
                                      controller.selectedNum++;
                                    } else {
                                      task.selected.value = false;
                                      if (controller.selectedNum > 0) {
                                        controller.selectedNum--;
                                      }
                                      if (controller.selectedNum == 0) {
                                        controller.setHasSelection(false);
                                      }
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: 72),
                              Obx(() {
                                if (speed.isEmpty) {
                                  return const SizedBox();
                                }
                                return Text(
                                  speed.value.padLeft(12),
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              }),
                              Text(
                                formatSize(task.size.toDouble()).padLeft(12),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
            );
          },
        ),
      ),
    );
  }

  List<DownloadTask> _getSelectedTasks(Downloader downloader) {
    final tasks = downloader.tasks.where((task) => task.selected.value);
    return tasks.toList();
  }

  Future<void> _addTasks({
    required bool retry,
    List<String>? failedUrls,
    required BuildContext context,
  }) async {
    final downloader = Get.find<Downloader>();
    Future<void> addAndStart(List<String> urls) async {
      final logs = Get.find<Logs>();
      logs.info('Add tasks from: $urls');
      await downloader.addtasks(urls).then((value) async {
        if (value.isEmpty) {
          return;
        }
        await _startTasks(tasks: value);
      });
    }

    List<String>? urls;
    final preFailedUrls = Set.from(downloader.failedUrls);
    if (retry && failedUrls != null) {
      urls = failedUrls;
    } else {
      final showFailedUrls = Get.find<Settings>().showFailedUrls.value;
      urls = await showDialog<List<String>>(
        context: context,
        builder: (context) => DialogInputUrls(
          failedUrls: showFailedUrls ? downloader.failedUrls.toList() : [],
        ),
      );
      if (urls == null || urls.isEmpty) return;
    }

    await addAndStart(urls);
    final curFailedUrls = downloader.failedUrls;
    final diffFailedUrls = curFailedUrls.difference(preFailedUrls).toList();
    if (diffFailedUrls.isNotEmpty) {
      if (!context.mounted) return;
      final retryConfirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addTasks),
            content: Text(AppLocalizations.of(context)!
                .addTasksFailed(downloader.failedUrls.length)),
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
      if (retryConfirm == null || !retryConfirm) return;
      downloader.failedUrls.removeAll(diffFailedUrls);
      if (!context.mounted) return;
      await _addTasks(
        retry: true,
        failedUrls: diffFailedUrls,
        context: context,
      );
    }
  }

  Future<void> _openDownloadDir() async {
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
  }

  Future<void> _startTasks({List<DownloadTask>? tasks}) async {
    final controller = Get.find<DownloadPageController>();
    controller.lock();
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      controller.unlock();
      return;
    }
    late final List<DownloadTask> tasksToStart;
    if (tasks != null) {
      tasksToStart = tasks;
    } else {
      tasks = _getSelectedTasks(downloader);
    }
    try {
      Future.microtask(() => downloader.startTasks(tasksToStart));
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to start tasks: $e');
    } finally {
      controller.unlock();
    }
  }

  Future<void> _pauseTasks() async {
    final controller = Get.find<DownloadPageController>();
    controller.lock();
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      controller.unlock();
      return;
    }
    try {
      final tasks = _getSelectedTasks(downloader);
      Future.microtask(() => downloader.pauseTasks(tasks));
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to pause tasks: $e');
    } finally {
      controller.unlock();
    }
  }

  Future<void> _cancelTasks() async {
    final controller = Get.find<DownloadPageController>();
    controller.lock();
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      controller.unlock();
      return;
    }
    try {
      final tasks = _getSelectedTasks(downloader);
      await downloader.cancelTasks(tasks);
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to cancel tasks: $e');
    } finally {
      controller.unlock();
      controller.clearSelection();
    }
  }

  Future<void> _deleteTasks(BuildContext context) async {
    final controller = Get.find<DownloadPageController>();
    controller.lock();
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      controller.unlock();
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTasks),
        content: Text(AppLocalizations.of(context)!.deleteTasksConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );
    if (shouldDelete != true) {
      controller.unlock();
      return;
    }
    try {
      final tasks = _getSelectedTasks(downloader);
      await downloader.deleteTasks(tasks);
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to delete tasks: $e');
    } finally {
      controller.unlock();
      controller.clearSelection();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<Settings>();
    final controller = Get.find<DownloadPageController>();
    return AppBar(
      title: Text(AppLocalizations.of(context)!.download),
      actions: [
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.of(context)!.addTasks,
          onPressed: settings.dbInitialized
              ? () async => await _addTasks(retry: false, context: context)
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.folder_open),
          tooltip: AppLocalizations.of(context)!.openDownloadDir,
          onPressed: () async => await _openDownloadDir(),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.play_arrow),
            tooltip: AppLocalizations.of(context)!.startTasks,
            onPressed:
                controller.hasSelection.value && !controller.buttonsLock.value
                    ? () async => await _startTasks()
                    : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.pause),
            tooltip: AppLocalizations.of(context)!.pauseTasks,
            onPressed:
                controller.hasSelection.value && !controller.buttonsLock.value
                    ? () async => await _pauseTasks()
                    : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.cancel),
            tooltip: AppLocalizations.of(context)!.cancelTasks,
            onPressed:
                controller.hasSelection.value && !controller.buttonsLock.value
                    ? () async => await _cancelTasks()
                    : null,
          ),
        ),
        Obx(
          () => IconButton(
            color: theme.colorScheme.primary,
            icon: const Icon(Icons.delete),
            tooltip: AppLocalizations.of(context)!.deleteTasks,
            onPressed:
                controller.hasSelection.value && !controller.buttonsLock.value
                    ? () async => await _deleteTasks(context)
                    : null,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Get.put(DownloadPageController());
    return AppPage(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildTaskList(theme.brightness == Brightness.dark),
      ),
    );
  }
}
