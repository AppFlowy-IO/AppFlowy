import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:flutter/material.dart';

extension NodeAttributesExtensions on Attributes {
  String? get heading {
    if (containsKey(BuiltInAttributeKey.subtype) &&
        containsKey(BuiltInAttributeKey.heading) &&
        this[BuiltInAttributeKey.subtype] == BuiltInAttributeKey.heading &&
        this[BuiltInAttributeKey.heading] is String) {
      return this[BuiltInAttributeKey.heading];
    }
    return null;
  }

  bool get quote {
    return containsKey(BuiltInAttributeKey.quote);
  }

  num? get number {
    if (containsKey(BuiltInAttributeKey.number) &&
        this[BuiltInAttributeKey.number] is num) {
      return this[BuiltInAttributeKey.number];
    }
    return null;
  }

  bool get code {
    if (containsKey(BuiltInAttributeKey.code) &&
        this[BuiltInAttributeKey.code] is bool) {
      return this[BuiltInAttributeKey.code];
    }
    return false;
  }

  bool get check {
    if (containsKey(BuiltInAttributeKey.checkbox) &&
        this[BuiltInAttributeKey.checkbox] is bool) {
      return this[BuiltInAttributeKey.checkbox];
    }
    return false;
  }
}

extension DeltaAttributesExtensions on Attributes {
  bool get bold {
    return (containsKey(BuiltInAttributeKey.bold) &&
        this[BuiltInAttributeKey.bold] == true);
  }

  bool get italic {
    return (containsKey(BuiltInAttributeKey.italic) &&
        this[BuiltInAttributeKey.italic] == true);
  }

  bool get underline {
    return (containsKey(BuiltInAttributeKey.underline) &&
        this[BuiltInAttributeKey.underline] == true);
  }

  bool get strikethrough {
    return (containsKey(BuiltInAttributeKey.strikethrough) &&
        this[BuiltInAttributeKey.strikethrough] == true);
  }

  static const whiteInt = 0XFFFFFFFF;

  Color? get color {
    if (containsKey(BuiltInAttributeKey.color) &&
        this[BuiltInAttributeKey.color] is String) {
      return Color(
        // If the parse fails returns white by default
        int.tryParse(this[BuiltInAttributeKey.color]) ?? whiteInt,
      );
    }
    return null;
  }

  Color? get backgroundColor {
    if (containsKey(BuiltInAttributeKey.backgroundColor) &&
        this[BuiltInAttributeKey.backgroundColor] is String) {
      return Color(
          int.tryParse(this[BuiltInAttributeKey.backgroundColor]) ?? whiteInt);
    }
    return null;
  }

  String? get href {
    if (containsKey(BuiltInAttributeKey.href) &&
        this[BuiltInAttributeKey.href] is String) {
      return this[BuiltInAttributeKey.href];
    }
    return null;
  }
}
