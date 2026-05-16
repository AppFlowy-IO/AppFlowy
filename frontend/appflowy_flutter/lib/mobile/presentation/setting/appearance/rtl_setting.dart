import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_trailing.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting.dart';

class RTLSetting extends StatelessWidget {
  const RTLSetting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textDirection =
        context.watch<AppearanceSettingsCubit>().state.textDirection;
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_textDirection_label.tr(),
      trailing: MobileSettingTrailing(
        text: _textDirectionLabelText(textDirection),
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showDragHandle: true,
          showDivider: false,
          title: LocaleKeys.settings_appearance_textDirection_label.tr(),
          builder: (context) {
            return Column(
              children: [
                FlowyOptionTile.checkbox(
                  text: LocaleKeys.settings_appearance_textDirection_ltr.tr(),
                  isSelected: textDirection == AppFlowyTextDirection.ltr,
                  onTap: () => applyTextDirectionAndPop(
                    context,
                    AppFlowyTextDirection.ltr,
                  ),
                ),
                FlowyOptionTile.checkbox(
                  showTopBorder: false,
                  text: LocaleKeys.settings_appearance_textDirection_rtl.tr(),
                  isSelected: textDirection == AppFlowyTextDirection.rtl,
                  onTap: () => applyTextDirectionAndPop(
                    context,
                    AppFlowyTextDirection.rtl,
                  ),
                ),
                FlowyOptionTile.checkbox(
                  showTopBorder: false,
                  text: LocaleKeys.settings_appearance_textDirection_auto.tr(),
                  isSelected: textDirection == AppFlowyTextDirection.auto,
                  onTap: () => applyTextDirectionAndPop(
                    context,
                    AppFlowyTextDirection.auto,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _textDirectionLabelText(AppFlowyTextDirection textDirection) {
    switch (textDirection) {
      case AppFlowyTextDirection.auto:
        return LocaleKeys.settings_appearance_textDirection_auto.tr();
      case AppFlowyTextDirection.rtl:
        return LocaleKeys.settings_appearance_textDirection_rtl.tr();
      case AppFlowyTextDirection.ltr:
        return LocaleKeys.settings_appearance_textDirection_ltr.tr();
    }
  }

  void applyTextDirectionAndPop(
    BuildContext context,
    AppFlowyTextDirection textDirection,
  ) {
    context.read<AppearanceSettingsCubit>().setTextDirection(textDirection);
    context
        .read<DocumentAppearanceCubit>()
        .syncDefaultTextDirection(textDirection.name);
    Navigator.pop(context);
  }
}
