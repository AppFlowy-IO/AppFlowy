import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class IconPickerPage extends StatelessWidget {
  const IconPickerPage({
    super.key,
    this.title,
    required this.onSelected,
  });

  final void Function(EmojiPickerResult) onSelected;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: FlowyText.semibold(
          title ?? LocaleKeys.titleBar_pageIcon.tr(),
          fontSize: 14.0,
        ),
        leading: const AppBarBackButton(),
      ),
      body: SafeArea(
        child: FlowyIconPicker(
          onSelected: onSelected,
        ),
      ),
    );
  }
}
