import 'package:eh_tagger/src/app/constants.dart';
import 'package:eh_tagger/src/app/logs.dart';
import 'package:eh_tagger/src/database/database.dart';
import 'package:eh_tagger/src/downloader/task.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class DownloadTasksDao {
  Future<List<DownloadTask>> queryTasks();

  Future<int> insertTask(DownloadTask task);

  Future<void> updateBytes({required int id, required int bytes});

  Future<void> updateStatus({required int id, required int status});

  Future<void> updateProgress({required int id, required double progress});

  Future<int> deleteTask({required int id});
}

class DownloadTasksDaoImpl implements DownloadTasksDao {
  static final DownloadTasksDaoImpl _instance =
      DownloadTasksDaoImpl._internal();
  late final Database _db;
  final _logs = Get.find<Logs>();

  factory DownloadTasksDaoImpl() {
    return _instance;
  }

  DownloadTasksDaoImpl._internal() {
    _db = AppDatabase().db;
  }

  @override
  Future<List<DownloadTask>> queryTasks() async {
    var maps = <Map<String, dynamic>>[];
    try {
      maps = await _db.query(downloadTasksTable);
    } catch (e) {
      _logs.error('Query download tasks: $e');
      return [];
    }
    _logs.info('Query download tasks: ${maps.length}');
    return List.generate(maps.length, (i) {
      return DownloadTask(
        id: maps[i]['id'] as int,
        name: maps[i]['name'] as String,
        path: maps[i]['path'] as String,
        size: maps[i]['size'] as int,
        eHentaiUrl: maps[i]['eHentaiUrl'] as String,
        downloadUrl: maps[i]['downloadUrl'] as String,
        status: TaskStatus.values[maps[i]['status'] as int],
        progress: maps[i]['progress'] as double,
        speed: '',
      );
    }).reversed.toList();
  }

  @override
  Future<int> insertTask(DownloadTask task) async {
    final result = await _db.insert(
      downloadTasksTable,
      {
        'name': task.name,
        'path': task.path,
        'size': task.size,
        'eHentaiUrl': task.eHentaiUrl,
        'downloadUrl': task.downloadUrl,
        'status': task.status.value.index,
        'progress': task.progress.value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _logs.info('Insert download task: ${task.name}');
    return result;
  }

  @override
  Future<void> updateBytes({required int id, required int bytes}) async {
    await _db.update(
      downloadTasksTable,
      {'bytes': bytes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateStatus({required int id, required int status}) async {
    await _db.update(
      downloadTasksTable,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateProgress(
      {required int id, required double progress}) async {
    await _db.update(
      downloadTasksTable,
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> deleteTask({required int id}) async {
    final result = await _db.delete(
      downloadTasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }
}
