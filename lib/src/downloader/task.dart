import 'package:get/get.dart';

class DownloadTask {
  int id;
  String name;
  String path;
  int size;
  String eHentaiUrl;
  String downloadUrl;
  Rx<TaskStatus> status;
  RxDouble progress;
  RxString speed;

  DownloadTask({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.eHentaiUrl,
    required this.downloadUrl,
    required TaskStatus status,
    required double progress,
    required String speed,
  })  : progress = progress.obs,
        status = status.obs,
        speed = speed.obs;

  factory DownloadTask.newTask({
    required String name,
    required String path,
    required int size,
    required String eHentaiUrl,
    required String downloadUrl,
  }) {
    return DownloadTask(
      id: 0,
      name: name,
      path: path,
      size: size,
      eHentaiUrl: eHentaiUrl,
      downloadUrl: downloadUrl,
      status: TaskStatus.paused,
      progress: 0.0,
      speed: '',
    );
  }
}

enum TaskStatus {
  running,
  paused,
  canceled,
  failed,
  completed,
}
