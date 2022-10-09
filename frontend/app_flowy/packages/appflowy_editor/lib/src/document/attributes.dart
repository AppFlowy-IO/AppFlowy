/// Attributes is used to describe the Node's information.
///
/// Please note: The keywords in [BuiltInAttributeKey] are reserved.
typedef Attributes = Map<String, dynamic>;

Attributes? composeAttributes(
  Attributes? base,
  Attributes? other, {
  keepNull = false,
}) {
  base ??= {};
  other ??= {};
  Attributes attributes = {
    ...base,
    ...other,
  };

  if (!keepNull) {
    attributes = Attributes.from(attributes)
      ..removeWhere((_, value) => value == null);
  }

  return attributes.isNotEmpty ? attributes : null;
}

Attributes invertAttributes(Attributes? base, Attributes? other) {
  base ??= {};
  other ??= {};
  final Attributes attributes = base.keys.fold({}, (previousValue, key) {
    if (other!.containsKey(key) && other[key] != base![key]) {
      previousValue[key] = base[key];
    }
    return previousValue;
  });
  return other.keys.fold(attributes, (previousValue, key) {
    if (!base!.containsKey(key) && other![key] != base[key]) {
      previousValue[key] = null;
    }
    return previousValue;
  });
}

int hashAttributes(Attributes base) => Object.hashAllUnordered(
      base.entries.map((e) => Object.hash(e.key, e.value)),
    );
