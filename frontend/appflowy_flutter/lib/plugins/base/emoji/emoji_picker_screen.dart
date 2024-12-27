import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../generated/locale_keys.g.dart';
import '../../../mobile/presentation/base/app_bar/app_bar.dart';
import '../../../shared/icon_emoji_picker/tab.dart';

class MobileEmojiPickerScreen extends StatelessWidget {
  const MobileEmojiPickerScreen({
    super.key,
    this.title,
    this.tabs = const [PickerTabType.emoji, PickerTabType.icon],
  });

  final String? title;
  final List<PickerTabType> tabs;

  static const routeName = '/emoji_picker';
  static const pageTitle = 'title';
  static const selectTabs = 'tabs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: title ?? LocaleKeys.titleBar_pageIcon.tr(),
      ),
      body: SafeArea(
        child: FlowyIconEmojiPicker(
          tabs: tabs,
          onSelectedEmoji: (r) {
            context.pop<EmojiIconData>(r.data);
          },
        ),
      ),
    );
  }
}
