import 'package:appflowy/plugins/base/emoji/emoji_picker_page.dart';
import 'package:flutter/material.dart';

class MobileEmojiPickerScreen extends StatelessWidget {
  static const routeName = '/emoji_picker';
  static const viewId = 'id';

  const MobileEmojiPickerScreen({
    super.key,
    required this.id,
  });

  /// view id
  final String id;

  @override
  Widget build(BuildContext context) {
    return EmojiPickerPage(
      id: id,
    );
  }
}
