Map<String, String> parseKeyValuePairs(String s, Set<String> targetKeys) {
  final result = <String, String>{};
  final pairs = s.split(';');
  for (final pair in pairs) {
    final _index = pair.indexOf(':');
    if (_index < 0) {
      continue;
    }
    final _key = pair.substring(0, _index).trim();
    if (targetKeys.contains(_key)) {
      result[_key] = pair.substring(_index + 1).trim();
    }
  }

  return result;
}
