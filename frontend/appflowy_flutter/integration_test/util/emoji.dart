import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension EmojiTestExtension on WidgetTester {
  /// Must call [openEmojiPicker] first
  Future<void> switchToEmojiList() async {
    final icon = find.byIcon(Icons.tag_faces);
    await tapButton(icon);
  }

  Future<void> tapEmoji(String emoji) async {
    final emojiWidget = find.text(emoji);
    await tapButton(emojiWidget);
  }
}
