import 'package:flutter_test/flutter_test.dart';
import 'package:anxiety_quran_book/services/search_index.dart';
import 'package:anxiety_quran_book/utils/persian_digits.dart';

void main() {
  test('toPersianDigits changes 0-9 to Persian digits', () {
    expect(toPersianDigits('12:30'), '۱۲:۳۰');
    expect(toPersianDigits('abc'), 'abc');
  });

  test('search ignores spaces', () {
    expect(
      SearchIndex.normalizeQuery('می شود'),
      SearchIndex.normalizeQuery('میشود'),
    );
  });

  test('search treats Arabic and Persian letters the same', () {
    expect(
      SearchIndex.normalizeQuery('كتاب'),
      SearchIndex.normalizeQuery('کتاب'),
    );
  });

  test('search treats Persian and English digits the same', () {
    expect(SearchIndex.normalizeQuery('۱۲۳'), '123');
  });
}