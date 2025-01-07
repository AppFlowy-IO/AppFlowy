import 'dart:io';

import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Icon;

extension StringExtension on String {
  static const _specialCharacters = r'\/:*?"<>| ';

  /// Encode a string to a file name.
  ///
  /// Normalizes the string to remove special characters and replaces the "\/:*?"<>|" with underscores.
  String toFileName() {
    final buffer = StringBuffer();
    for (final character in characters) {
      if (_specialCharacters.contains(character)) {
        buffer.write('_');
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }

  /// Returns the file size of the file at the given path.
  ///
  /// Returns null if the file does not exist.
  int? get fileSize {
    final file = File(this);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return null;
  }

  /// Returns true if the string is a appflowy cloud url.
  bool get isAppFlowyCloudUrl => appflowyCloudUrlRegex.hasMatch(this);

  /// Returns the color of the string.
  ///
  /// ONLY used for the cover.
  Color? coverColor(BuildContext context) {
    // try to parse the color from the tint id,
    //  if it fails, try to parse the color as a hex string
    return FlowyTint.fromId(this)?.color(context) ?? tryToColor();
  }

  String orDefault(String defaultValue) {
    return isEmpty ? defaultValue : this;
  }
}

extension NullableStringExtension on String? {
  String orDefault(String defaultValue) {
    return this?.isEmpty ?? true ? defaultValue : this ?? '';
  }
}

extension IconExtension on String {
  Icon? get icon {
    final values = split('/');
    if (values.length != 2) {
      return null;
    }
    final iconGroup = IconGroup(name: values.first, icons: []);
    if (kDebugMode) {
      // Ensure the icon group and icon exist
      assert(kIconGroups!.any((group) => group.name == values.first));
      assert(
        kIconGroups!
            .firstWhere((group) => group.name == values.first)
            .icons
            .any((icon) => icon.name == values.last),
      );
    }
    return Icon(
      content: values.last,
      name: values.last,
      keywords: [],
    )..iconGroup = iconGroup;
  }
}

extension CounterExtension on String {
  Counters getCounter() {
    final wordCount = wordRegex.allMatches(this).length;
    final charCount = runes.length;
    return Counters(wordCount: wordCount, charCount: charCount);
  }
}
