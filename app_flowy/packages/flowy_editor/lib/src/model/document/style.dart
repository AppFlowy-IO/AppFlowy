import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

import 'attribute.dart';

class Style {
  Style() : _attributes = <String, Attribute>{};

  Style.attr(this._attributes);

  final Map<String, Attribute> _attributes;

  static Style fromJson(Map<String, dynamic>? attributes) {
    if (attributes == null) {
      return Style();
    }
    final result = attributes.map((key, value) {
      final attr = Attribute.fromKeyValue(key, value);
      return MapEntry<String, Attribute>(key, attr);
    });
    return Style.attr(result);
  }

  Map<String, dynamic>? toJson() => _attributes.isEmpty
      ? null
      : _attributes.map<String, dynamic>((_, attr) {
          return MapEntry<String, dynamic>(attr.key, attr.value);
        });

  // Properties

  Map<String, Attribute> get attributes => _attributes;

  Iterable<String> get keys => _attributes.keys;

  Iterable<Attribute> get values => _attributes.values;

  bool get isEmpty => _attributes.isEmpty;

  bool get isNotEmpty => _attributes.isNotEmpty;

  bool get isInline => isNotEmpty && values.every((ele) => ele.isInline);

  bool get isIgnored => isNotEmpty && values.every((ele) => ele.isIgnored);

  Attribute get single => values.single;

  bool containsKey(String key) => _attributes.containsKey(key);

  Attribute? getBlockExceptHeader() {
    for (final value in values) {
      if (value.isBlockExceptHeader) {
        return value;
      }
    }
    return null;
  }

  // Operators

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
    other.values.forEach((attr) {
      result = result.merge(attr);
    });
    return result;
  }

  Style removeAll(Set<Attribute> attributes) {
    final merged = Map<String, Attribute>.from(_attributes);
    attributes.map((ele) => ele.key).forEach(merged.remove);
    return Style.attr(merged);
  }

  Style put(Attribute attribute) {
    final merged = Map<String, Attribute>.from(_attributes);
    merged[attribute.key] = attribute;
    return Style.attr(merged);
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
