import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import 'attribute.dart';

/* Collection of style attributes */
class Style {
  Style() : _attributes = <String, Attribute>{};

  Style.attr(this._attributes);

  final Map<String, Attribute> _attributes;

  static Style fromJson(Map<String, dynamic>? attributes) {
    if (attributes == null) {
      return Style();
    }

    final result = attributes.map((key, dynamic value) {
      final attr = Attribute.fromKeyValue(key, value);
      return MapEntry<String, Attribute>(
          key, attr ?? Attribute(key, AttributeScope.IGNORE, value));
    });
    return Style.attr(result);
  }

  Map<String, dynamic>? toJson() => _attributes.isEmpty
      ? null
      : _attributes.map<String, dynamic>((_, attribute) =>
          MapEntry<String, dynamic>(attribute.key, attribute.value));

  Iterable<String> get keys => _attributes.keys;

  Iterable<Attribute> get values => _attributes.values.sorted(
      (a, b) => Attribute.getRegistryOrder(a) - Attribute.getRegistryOrder(b));

  Map<String, Attribute> get attributes => _attributes;

  bool get isEmpty => _attributes.isEmpty;

  bool get isNotEmpty => _attributes.isNotEmpty;

  bool get isInline => isNotEmpty && values.every((item) => item.isInline);

  bool get isIgnored =>
      isNotEmpty && values.every((item) => item.scope == AttributeScope.IGNORE);

  Attribute get single => _attributes.values.single;

  bool containsKey(String key) => _attributes.containsKey(key);

  Attribute? getBlockExceptHeader() {
    for (final val in values) {
      if (val.isBlockExceptHeader && val.value != null) {
        return val;
      }
    }
    for (final val in values) {
      if (val.isBlockExceptHeader) {
        return val;
      }
    }
    return null;
  }

  Map<String, Attribute> getBlocksExceptHeader() {
    final m = <String, Attribute>{};
    attributes.forEach((key, value) {
      if (Attribute.blockKeysExceptHeader.contains(key)) {
        m[key] = value;
      }
    });
    return m;
  }

  Style merge(Attribute attribute) {
    final merged = Map<String, Attribute>.from(_attributes);
    if (attribute.value == null) {
      merged.remove(attribute.key);
    } else {
      merged[attribute.key] = attribute;
    }
    return Style.attr(merged);
  }

  Style mergeAll(Style other) {
    var result = Style.attr(_attributes);
    for (final attribute in other.values) {
      result = result.merge(attribute);
    }
    return result;
  }

  Style removeAll(Set<Attribute> attributes) {
    final merged = Map<String, Attribute>.from(_attributes);
    attributes.map((item) => item.key).forEach(merged.remove);
    return Style.attr(merged);
  }

  Style put(Attribute attribute) {
    final m = Map<String, Attribute>.from(attributes);
    m[attribute.key] = attribute;
    return Style.attr(m);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Style) {
      return false;
    }
    final typedOther = other;
    const eq = MapEquality<String, Attribute>();
    return eq.equals(_attributes, typedOther._attributes);
  }

  @override
  int get hashCode {
    final hashes =
        _attributes.entries.map((entry) => hash2(entry.key, entry.value));
    return hashObjects(hashes);
  }

  @override
  String toString() => "{${_attributes.values.join(', ')}}";
}
