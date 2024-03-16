import 'package:eh_tagger/src/calibre/book.dart';
import 'package:eh_tagger/src/database/dao/books.dart';
import 'package:get/get.dart';

class BooksController extends GetxController {
  final _books = <Book>[].obs;

  List<Book> get books => _books;

  Book getBook(int index) => _books[index];

  int get length => _books.length;

  int getIndex(int bookId) => _books.indexWhere((book) => book.id == bookId);

  Future<void> queryBooks() async {
    final booksDao = BooksDaoImpl();
    final books = await booksDao.queryBooks();
    if (books.isNotEmpty) {
      _books.value = books;
    }
  }

  void addBook(Book book) {
    _books.insert(0, book);
  }

  void addBooks(Iterable<Book> books) {
    _books.insertAll(0, books);
  }

  void removeBooks(List<int> ids) {
    _books.removeWhere((book) => ids.contains(book.id));
  }
}
