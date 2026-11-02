import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/book.dart';

/// Reads assets/book.json and turns it into a Book object.
Future<Book> loadBook() async {
  final text = await rootBundle.loadString('assets/book.json');
  final data = jsonDecode(text) as Map<String, dynamic>;
  return Book.fromJson(data);
}
