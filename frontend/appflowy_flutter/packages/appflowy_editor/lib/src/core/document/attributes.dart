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

Attributes invertAttributes(Attributes? from, Attributes? to) {
  from ??= {};
  to ??= {};
  final attributes = Attributes.from({});

  // key in from but not in to, or value is different
  for (final entry in from.entries) {
    if ((!to.containsKey(entry.key) && entry.value != null) ||
        to[entry.key] != entry.value) {
      attributes[entry.key] = entry.value;
    }
  }

  // key in to but not in from, or value is different
  for (final entry in to.entries) {
    if (!from.containsKey(entry.key) && entry.value != null) {
      attributes[entry.key] = null;
    }
  }

  return attributes;
}

int hashAttributes(Attributes base) => Object.hashAllUnordered(
      base.entries.map((e) => Object.hash(e.key, e.value)),
    );
