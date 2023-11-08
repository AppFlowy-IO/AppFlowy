import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/plugins/base/icon/icon_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileEmojiPickerScreen extends StatelessWidget {
  static const routeName = '/emoji_picker';

  const MobileEmojiPickerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconPickerPage(
      onSelected: (result) {
        context.pop<EmojiPickerResult>(result);
      },
    );
  }
}
