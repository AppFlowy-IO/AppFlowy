import 'package:appflowy/plugins/base/icon/icon_picker_page.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileEmojiPickerScreen extends StatelessWidget {
  const MobileEmojiPickerScreen({super.key, this.title});

  final String? title;

  static const routeName = '/emoji_picker';
  static const pageTitle = 'title';

  @override
  Widget build(BuildContext context) {
    return IconPickerPage(
      title: title,
      onSelected: (result) {
        context.pop<EmojiPickerResult>(result);
      },
    );
  }
}
