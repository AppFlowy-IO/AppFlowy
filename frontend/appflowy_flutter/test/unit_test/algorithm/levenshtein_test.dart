import 'package:appflowy/util/levenshtein.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Levenshtein distance between identical strings', () {
    final distance = levenshtein('abc', 'abc');
    expect(distance, 0);
  });

  test('Levenshtein distance between strings of different lengths', () {
    final distance = levenshtein('kitten', 'sitting');
    expect(distance, 3);
  });

  test('Levenshtein distance between case-insensitive strings', () {
    final distance = levenshtein('Hello', 'hello', caseSensitive: false);
    expect(distance, 0);
  });

  test('Levenshtein distance between strings with substitutions', () {
    final distance = levenshtein('kitten', 'smtten');
    expect(distance, 2);
  });

  test('Levenshtein distance between strings with deletions', () {
    final distance = levenshtein('kitten', 'kiten');
    expect(distance, 1);
  });

  test('Levenshtein distance between strings with insertions', () {
    final distance = levenshtein('kitten', 'kitxten');
    expect(distance, 1);
  });
}
