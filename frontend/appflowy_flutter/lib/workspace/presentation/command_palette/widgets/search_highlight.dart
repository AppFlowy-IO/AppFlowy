import 'package:flutter/painting.dart';

final _queryWhitespace = RegExp(r'\s+');

TextSpan buildSearchHighlightSpan({
  required String content,
  required String? query,
  required TextStyle normal,
  required TextStyle highlight,
}) {
  final trimmedQuery = query?.trim() ?? '';
  if (trimmedQuery.isEmpty) {
    return TextSpan(text: content, style: normal);
  }

  final terms = trimmedQuery.split(_queryWhitespace).toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final pattern = RegExp(
    terms.map(RegExp.escape).join('|'),
    caseSensitive: false,
    unicode: true,
  );

  final spans = <TextSpan>[];
  var offset = 0;
  for (final match in pattern.allMatches(content)) {
    if (match.start > offset) {
      spans.add(TextSpan(text: content.substring(offset, match.start)));
    }
    spans.add(TextSpan(text: match.group(0), style: highlight));
    offset = match.end;
  }
  if (spans.isEmpty) {
    return TextSpan(text: content, style: normal);
  }
  if (offset < content.length) {
    spans.add(TextSpan(text: content.substring(offset)));
  }
  return TextSpan(style: normal, children: spans);
}
