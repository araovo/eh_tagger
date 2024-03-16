import 'dart:async';

import 'package:eh_tagger/src/app/constants.dart';

class TaskMonitor {
  int prevReceivedBytes = 0;
  int receivedBytes = 0;
  String speed = '';
  Timer? _timer;

  TaskMonitor();

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final receivedBytesDiff = receivedBytes - prevReceivedBytes;
      prevReceivedBytes = receivedBytes;
      final speed = _formatSpeed(receivedBytesDiff.toDouble());
      this.speed = speed;
    });
  }

  void stop() {
    _timer?.cancel();
    speed = '';
  }

  void updateReceivedBytes(int receivedBytes) {
    this.receivedBytes = receivedBytes;
  }

  String _formatSpeed(double speed) {
    var index = 0;
    while (speed >= 1024 && index < speedUnits.length - 1) {
      speed /= 1024;
      index++;
    }
    return '${speed.toStringAsFixed(2)} ${speedUnits[index]}';
  }
}
