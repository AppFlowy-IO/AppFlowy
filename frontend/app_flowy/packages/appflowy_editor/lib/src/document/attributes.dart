typedef Attributes = Map<String, dynamic>;

int hashAttributes(Attributes attributes) {
  return Object.hashAllUnordered(
      attributes.entries.map((e) => Object.hash(e.key, e.value)));
}

Attributes invertAttributes(Attributes? attr, Attributes? base) {
  attr ??= {};
  base ??= {};
  final Attributes baseInverted = base.keys.fold({}, (memo, key) {
    if (base![key] != attr![key] && attr.containsKey(key)) {
      memo[key] = base[key];
    }
    return memo;
  });
  return attr.keys.fold(baseInverted, (memo, key) {
    if (attr![key] != base![key] && !base.containsKey(key)) {
      memo[key] = null;
    }
    return memo;
  });
}

Attributes? composeAttributes(Attributes? a, Attributes? b,
    [bool keepNull = false]) {
  a ??= {};
  b ??= {};
  Attributes attributes = {...b};

  if (!keepNull) {
    attributes = Map.from(attributes)..removeWhere((_, value) => value == null);
  }

  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) {
      attributes[entry.key] = entry.value;
    }
  }

  return attributes.isNotEmpty ? attributes : null;
}
