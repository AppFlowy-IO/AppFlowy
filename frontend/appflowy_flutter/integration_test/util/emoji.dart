import 'package:emoji_mart/emoji_mart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base.dart';

extension EmojiTestExtension on WidgetTester {
  Future<void> tapEmoji(String emoji) async {
    final emojiWidget = find.descendant(
      of: find.byType(EmojiPicker),
      matching: find.text(emoji),
    );
    await tapButton(emojiWidget);
  }
}
