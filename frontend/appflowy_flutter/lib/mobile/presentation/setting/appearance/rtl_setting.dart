import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting.dart';

class RTLSetting extends StatelessWidget {
  const RTLSetting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layoutDirection =
        context.watch<AppearanceSettingsCubit>().state.layoutDirection;
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_textDirection_label.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            _textDirectionLabelText(layoutDirection),
            color: theme.colorScheme.onSurface,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showDragHandle: true,
          showDivider: false,
          title: LocaleKeys.settings_appearance_textDirection_label.tr(),
          builder: (context) {
            final layoutDirection =
                context.watch<AppearanceSettingsCubit>().state.layoutDirection;
            return Column(
              children: [
                FlowyOptionTile.checkbox(
                  text: LocaleKeys.settings_appearance_textDirection_ltr.tr(),
                  isSelected: layoutDirection == LayoutDirection.ltrLayout,
                  onTap: () {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setLayoutDirection(LayoutDirection.ltrLayout);
                    Navigator.pop(context);
                  },
                ),
                FlowyOptionTile.checkbox(
                  showTopBorder: false,
                  text: LocaleKeys.settings_appearance_textDirection_rtl.tr(),
                  isSelected: layoutDirection == LayoutDirection.rtlLayout,
                  onTap: () {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setLayoutDirection(LayoutDirection.rtlLayout);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _textDirectionLabelText(LayoutDirection? textDirection) {
    switch (textDirection) {
      case LayoutDirection.rtlLayout:
        return LocaleKeys.settings_appearance_textDirection_rtl.tr();
      case LayoutDirection.ltrLayout:
      default:
        return LocaleKeys.settings_appearance_textDirection_ltr.tr();
    }
  }
}
