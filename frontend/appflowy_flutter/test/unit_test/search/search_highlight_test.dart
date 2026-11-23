import 'package:appflowy/workspace/presentation/command_palette/widgets/search_highlight.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normal = TextStyle(fontWeight: FontWeight.normal);
  const highlight = TextStyle(backgroundColor: Color(0xFFFFFF00));

  void checkMatches(String text, String? query, List<String> matches) {
    final span = buildSearchHighlightSpan(
      content: text,
      query: query,
      normal: normal,
      highlight: highlight,
    );
    expect(span.toPlainText(), text);
    expect(span.style, normal);
    expect(
      span.children
              ?.whereType<TextSpan>()
              .where((child) => child.style == highlight)
              .map((child) => child.text) ??
          [],
      matches,
    );
  }

  test('highlights separated, repeated query terms case-insensitively', () {
    checkMatches(
      'NOTES for the June release. Notes from May.',
      ' release\t notes\n ',
      ['NOTES', 'release', 'Notes'],
    );
  });

  test('highlights adjacent matches without changing the result text', () {
    checkMatches('HelloHELLOhelloHeLLo', 'Hello', [
      'Hello',
      'HELLO',
      'hello',
      'HeLLo',
    ]);
  });

  test('prefers a longer term when matches start at the same position', () {
    checkMatches('AppFlowy app', 'app AppFlowy', ['AppFlowy', 'app']);
  });

  test('treats search punctuation literally and preserves Unicode text', () {
    checkMatches('C++ and CAFÉ (v2)', 'c++ café (v2)', [
      'C++',
      'CAFÉ',
      '(v2)',
    ]);
  });

  test('keeps text plain when the query is absent, blank, or unmatched', () {
    checkMatches('Release notes', null, []);
    checkMatches('Release notes', ' \t ', []);
    checkMatches('Release notes', 'missing', []);
  });
}
