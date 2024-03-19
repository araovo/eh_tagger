import 'dart:io';

import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/app/settings.dart';
import 'package:eh_tagger/src/app/storage.dart';
import 'package:eh_tagger/src/downloader/downloader.dart';
import 'package:eh_tagger/src/downloader/task.dart';
import 'package:eh_tagger/src/downloader/task_handler.dart';
import 'package:eh_tagger/src/pages/widgets/page.dart';
import 'package:eh_tagger/src/pages/widgets/setting_item/dialog_input_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _multiSelectedBookId = <int>{};
  bool _buttonsLock = false;

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
            final id = task.id;
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
                              Checkbox(
                                value: _multiSelectedBookId.contains(id),
                                onChanged: (value) {
                                  setState(() {
                                    if (value!) {
                                      _multiSelectedBookId.add(id);
                                    } else {
                                      _multiSelectedBookId.remove(id);
                                    }
                                  });
                                },
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

  Future<void> _addTasks() async {
    final urls = await showDialog<List<String>>(
      context: context,
      builder: (context) => const DialogInputUrls(),
    );
    if (urls == null || urls.isEmpty) return;
    final logs = Get.find<Logs>();
    logs.info('Add tasks from: $urls');
    final downloader = Get.find<Downloader>();
    await downloader.addtasks(urls).then((value) async {
      if (value.isEmpty) {
        return;
      }
      await _startTasks(value);
    });
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

  Future<void> _startTasks(Iterable<int> ids) async {
    setState(() {
      _buttonsLock = true;
    });
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      setState(() {
        _buttonsLock = false;
      });
      return;
    }
    try {
      Future.microtask(() => downloader.startTasks(ids));
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to start tasks: $e');
    } finally {
      setState(() {
        _buttonsLock = false;
      });
    }
  }

  Future<void> _pauseTasks() async {
    setState(() {
      _buttonsLock = true;
    });
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      setState(() {
        _buttonsLock = false;
      });
      return;
    }
    try {
      Future.microtask(() => downloader.pauseTasks(_multiSelectedBookId));
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to pause tasks: $e');
    } finally {
      setState(() {
        _buttonsLock = false;
      });
    }
  }

  Future<void> _cancelTasks() async {
    setState(() {
      _buttonsLock = true;
    });
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      setState(() {
        _buttonsLock = false;
      });
      return;
    }
    try {
      await downloader.cancelTasks(_multiSelectedBookId);
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to cancel tasks: $e');
    } finally {
      setState(() {
        _multiSelectedBookId.clear();
        _buttonsLock = false;
      });
    }
  }

  Future<void> _deleteTasks() async {
    setState(() {
      _buttonsLock = true;
    });
    final downloader = Get.find<Downloader>();
    if (downloader.tasks.isEmpty) {
      setState(() {
        _buttonsLock = false;
      });
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
      setState(() {
        _buttonsLock = false;
      });
      return;
    }
    try {
      await downloader.deleteTasks(_multiSelectedBookId);
    } catch (e) {
      final logs = Get.find<Logs>();
      logs.error('Failed to delete tasks: $e');
    } finally {
      setState(() {
        _multiSelectedBookId.clear();
        _buttonsLock = false;
      });
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final theme = Theme.of(context);
    final settings = Get.find<Settings>();
    return AppBar(
      title: Text(AppLocalizations.of(context)!.download),
      actions: [
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.add),
          tooltip: AppLocalizations.of(context)!.addTasks,
          onPressed:
              settings.dbInitialized ? () async => await _addTasks() : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.folder_open),
          tooltip: AppLocalizations.of(context)!.openDownloadDir,
          onPressed: () async => await _openDownloadDir(),
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.play_arrow),
          tooltip: AppLocalizations.of(context)!.startTasks,
          onPressed: _multiSelectedBookId.isNotEmpty && !_buttonsLock
              ? () async => await _startTasks(_multiSelectedBookId)
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.pause),
          tooltip: AppLocalizations.of(context)!.pauseTasks,
          onPressed: _multiSelectedBookId.isNotEmpty && !_buttonsLock
              ? () async => await _pauseTasks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.cancel),
          tooltip: AppLocalizations.of(context)!.cancelTasks,
          onPressed: _multiSelectedBookId.isNotEmpty && !_buttonsLock
              ? () async => await _cancelTasks()
              : null,
        ),
        IconButton(
          color: theme.colorScheme.primary,
          icon: const Icon(Icons.delete),
          tooltip: AppLocalizations.of(context)!.deleteTasks,
          onPressed: _multiSelectedBookId.isNotEmpty && !_buttonsLock
              ? () async => await _deleteTasks()
              : null,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPage(
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildTaskList(theme.brightness == Brightness.dark),
      ),
    );
  }
}
