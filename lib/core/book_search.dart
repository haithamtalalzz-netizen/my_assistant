import 'dart:convert';

import 'package:http/http.dart' as http;

/// نتيجة بحث عن كتاب من Open Library.
class BookHit {
  final String title;
  final String author;
  final int pages;
  const BookHit(
      {required this.title, required this.author, required this.pages});
}

/// بحث عن الكتب من Open Library — API مجانى مفتوح بلا مفتاح ولا حساب.
/// يرجّع قائمة فاضية عند أى فشل (شبكة/حظر) فيرجع المستخدم للإضافة اليدوية.
class BookSearch {
  static Future<List<BookHit>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.parse(
        'https://openlibrary.org/search.json?q=${Uri.encodeQueryComponent(q)}'
        '&limit=15&fields=title,author_name,number_of_pages_median');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final docs = (data['docs'] as List?) ?? const [];
      final out = <BookHit>[];
      for (final d in docs) {
        if (d is! Map) continue;
        final title = (d['title'] as String?)?.trim() ?? '';
        if (title.isEmpty) continue;
        final authors = (d['author_name'] as List?)?.cast<Object?>();
        final author =
            (authors != null && authors.isNotEmpty) ? '${authors.first}' : '';
        final pages = (d['number_of_pages_median'] as num?)?.round() ?? 0;
        out.add(BookHit(title: title, author: author, pages: pages));
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}
