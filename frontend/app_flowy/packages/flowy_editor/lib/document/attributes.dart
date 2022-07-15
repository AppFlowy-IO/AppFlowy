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
    if (attr![key] != base![key] && base.containsKey(key)) {
      memo[key] = null;
    }
    return memo;
  });
}

Attributes? composeAttributes(Attributes? a, Attributes? b) {
  a ??= {};
  b ??= {};
  final Attributes attributes = {};
  attributes.addAll(b);

  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) {
      attributes[entry.key] = entry.value;
    }
  }

  if (attributes.isEmpty) {
    return null;
  }

  return attributes;
}
