import 'dart:convert';
import 'dart:io';

import 'package:eh_tagger/src/database/dao/books.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:eh_tagger/src/calibre/book.dart';
import 'package:path/path.dart';

class EditDialog extends StatefulWidget {
  final List<Book> books;

  const EditDialog({super.key, required this.books});

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  int _index = 0;
  final _formKey = GlobalKey<FormState>();
  late Book _currentBook;
  bool _isModified = false;
  final _pathController = TextEditingController();
  final _coverPathController = TextEditingController();
  final _titleController = TextEditingController();
  final _eHentaiUrlController = TextEditingController();
  final _authorsController = TextEditingController();
  final _publisherController = TextEditingController();
  final _identifiersController = TextEditingController();
  final _tagsController = TextEditingController();
  final _languagesController = TextEditingController();
  final _ratingController = TextEditingController();
  FilePickerResult? _result;
  final booksDao = BooksDaoImpl();

  void _fieldChanged() {
    setState(() {
      _isModified = true;
    });
  }

  void _updateControllers() {
    _pathController.text = _currentBook.path;
    _coverPathController.text = _currentBook.coverPath;
    _titleController.text = _currentBook.metadata.title;
    _eHentaiUrlController.text = _currentBook.metadata.eHentaiUrl;
    _authorsController.text = _currentBook.metadata.authors?.join(',') ?? '';
    _publisherController.text = _currentBook.metadata.publisher ?? '';
    _identifiersController.text = _currentBook.metadata.identifiers != null
        ? jsonEncode(_currentBook.metadata.identifiers)
        : '{}';
    _tagsController.text = _currentBook.metadata.tags?.join(',') ?? '';
    _languagesController.text =
        _currentBook.metadata.languages?.join(',') ?? '';
    _ratingController.text = _currentBook.metadata.rating?.toString() ?? '';
    _result = null;
  }

  @override
  void initState() {
    super.initState();
    _currentBook = widget.books[_index];
    _updateControllers();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (!_eHentaiUrlController.text.endsWith('/') &&
          _eHentaiUrlController.text.isNotEmpty) {
        _eHentaiUrlController.text += '/';
      }
      _formKey.currentState!.save();
      if (_result != null) {
        final dst = File(_currentBook.coverPath);
        if (await dst.exists()) {
          await dst.delete();
        }
        final src = File(_result!.files.single.path!);
        final ext = extension(src.path);
        await src.copy(join(_currentBook.dir, 'cover$ext'));
        setState(() {
          _coverPathController.text = _currentBook.coverPath;
        });
      }
      await booksDao.updateBook(_currentBook);
      setState(() {
        _isModified = false;
      });
    }
  }

  void _nextBook() {
    setState(() {
      _index++;
      _currentBook = widget.books[_index];
      _updateControllers();
      _isModified = false;
    });
  }

  void _previousBook() {
    setState(() {
      _index--;
      _currentBook = widget.books[_index];
      _updateControllers();
      _isModified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.editBooks,
                        style: Theme.of(context).textTheme.titleLarge),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _isModified ? _save : null,
                          tooltip: AppLocalizations.of(context)!.save,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _index > 0 ? _previousBook : null,
                        ),
                        Text(' ${_index + 1}/${widget.books.length} ',
                            style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _index < widget.books.length - 1
                              ? _nextBook
                              : null,
                        ),
                      ],
                    )
                  ],
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        enabled: false,
                        controller: _pathController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.bookPath,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        readOnly: true,
                        controller: _coverPathController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.bookCoverPath,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.photo_library),
                            onPressed: () async {
                              _result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (_result != null) {
                                setState(() {
                                  _coverPathController.text =
                                      _result!.files.single.path!;
                                  _fieldChanged();
                                });
                              }
                            },
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.bookTitle,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.title = value!;
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.endsWith('/')) value += '/';
                            final pattern = RegExp(
                                r'^https?://(e-hentai\.org|exhentai\.org)/g/\d+/\w+/$');
                            if (!pattern.hasMatch(value)) {
                              return 'Invalid E-Hentai URL';
                            }
                          }
                          return null;
                        },
                        controller: _eHentaiUrlController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.eHentaiUrl,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.eHentaiUrl = value!;
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        controller: _authorsController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.authors,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.authors = value?.split(', ');
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        controller: _publisherController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.publisher,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.publisher = value;
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value != null) {
                            if (value.isNotEmpty) {
                              try {
                                jsonDecode(value);
                              } catch (_) {
                                return 'Invalid JSON';
                              }
                            } else if (value.isEmpty) {
                              return 'Invalid JSON';
                            }
                          }
                          return null;
                        },
                        controller: _identifiersController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.identifiers,
                        ),
                        onSaved: (value) {
                          if (value != null) {
                            _currentBook.metadata.identifiers =
                                jsonDecode(value);
                          }
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.tags,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.tags = value?.split(',');
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        controller: _languagesController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.languages,
                        ),
                        onSaved: (value) {
                          _currentBook.metadata.languages = value?.split(',');
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                      TextFormField(
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final rating = double.tryParse(value);
                            if (rating == null || rating < 0 || rating > 10) {
                              return 'Invalid rating';
                            }
                          }
                          return null;
                        },
                        controller: _ratingController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.rating,
                        ),
                        onSaved: (value) {
                          if (value != null) {
                            if (value.isNotEmpty) {
                              _currentBook.metadata.rating =
                                  double.parse(value);
                            } else {
                              _currentBook.metadata.rating = null;
                            }
                          }
                        },
                        onChanged: (_) {
                          _fieldChanged();
                        },
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: null,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
