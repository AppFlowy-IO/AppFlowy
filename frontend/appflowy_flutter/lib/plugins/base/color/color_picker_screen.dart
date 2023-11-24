import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/color/color_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileColorPickerScreen extends StatelessWidget {
  static const routeName = '/color_picker';
  static const pageTitle = 'title';

  const MobileColorPickerScreen({
    super.key,
    this.title,
  });

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
        leading: AppBarBackButton(
          onTap: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FlowyMobileColorPicker(
          onSelectedColor: (option) => context.pop(option),
        ),
      ),
    );
  }
}
