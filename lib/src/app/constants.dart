import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const packageName = 'com.araovo.eh-tagger';
const appVersion = 'v1.1.2+5';
const configFileName = 'config.json';
const dbFileName = 'app.sqlite';
const transDbFileName = 'ehTagTrans.sqlite';
const booksDirectoryName = 'books';
const downloadTemporaryDirName = 'eh_tagger_download';
const downloadDirName = 'download';
const tempDirectoryName = 'temp';
const tempCalibreLibraryDirName = 'Library';
const bookCoverFileNameWithNoExtension = 'cover';
const transDbApiUrl =
    'https://api.github.com/repos/EhTagTranslation/Database/releases/latest';
const transDbArchiveUrl =
    'https://github.com/EhTagTranslation/Database/archive/refs/tags';
const transDbArchiveRename = 'Database';
const magazineList = ['magazine', '杂志', ''];
const missingRowsList = [
  ['category', '分类', '该作品所处分类'],
  ['magazine', '杂志', '多个作品合集'],
  ['rows', '内容索引', '标签列表的行名，即标签的命名空间。数据来自 https://ehwiki.org/wiki/Namespace'],
  ['translator', '翻译者', '将作品文字翻译成别的文字'],
  ['uploader', '上传者', '该作品上传所有者']
];

const windowOptions = WindowOptions(
  title: 'EH Tagger',
  size: Size(800, 600),
  minimumSize: Size(700, 500),
  center: true,
);

const databaseVersion = 2;

const booksTable = 'books';
const downloadTasksTable = 'downloadTasks';

const createBooksTable = '''
CREATE TABLE $booksTable (
  id INTEGER PRIMARY KEY,
  dir TEXT NOT NULL,
  path TEXT NOT NULL,
  coverPath TEXT NOT NULL,
  title TEXT NOT NULL,
  authors TEXT,
  publisher TEXT,
  identifiers TEXT,
  tags TEXT,
  languages TEXT,
  rating REAL,
  eHentaiUrl TEXT NOT NULL
);
''';
const createDownloadTasksTable = '''
CREATE TABLE $downloadTasksTable (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  path TEXT NOT NULL,
  size INTEGER NOT NULL,
  eHentaiUrl TEXT NOT NULL,
  downloadUrl TEXT NOT NULL,
  status INTEGER NOT NULL,
  progress REAL NOT NULL
);
''';

const taskRunningColor = Colors.green;
const taskPausedColor = Colors.orange;
const taskFailedColor = Colors.red;
const taskCompletedColor = Colors.blue;

const sizeUnits = ['B', 'KB', 'MB', 'GB', 'TB'];
const speedUnits = ['B/s', 'KB/s', 'MB/s', 'GB/s', 'TB/s'];
