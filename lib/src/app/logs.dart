import 'package:get/get.dart';
import 'package:intl/intl.dart';

class Logs extends GetxController {
  final data = <Log>[].obs;

  void _addLog(String level, String message) {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    data.add(Log(timestamp, level, message));
  }

  void info(String message) {
    _addLog('INFO', message);
  }

  void warning(String message) {
    _addLog('WARN', message);
  }

  void error(String message) {
    _addLog('ERROR', message);
  }

  void clear() {
    data.clear();
  }
}

class Log {
  final String timestamp;
  final String level;
  final String message;

  Log(this.timestamp, this.level, this.message);
}
