import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_setting_entry_template.dart';

class LayoutDirectionSetting extends StatelessWidget {
  const LayoutDirectionSetting({
    super.key,
    required this.currentLayoutDirection,
  });

  final LayoutDirection currentLayoutDirection;

  @override
  Widget build(BuildContext context) {
    return FlowySettingListTile(
      label: LocaleKeys.settings_appearance_layoutDirection_label.tr(),
      hint: LocaleKeys.settings_appearance_layoutDirection_hint.tr(),
      trailing: [
        FlowySettingValueDropDown(
          currentValue: _layoutDirectionLabelText(currentLayoutDirection),
          popupBuilder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _layoutDirectionItemButton(context, LayoutDirection.ltrLayout),
              _layoutDirectionItemButton(context, LayoutDirection.rtlLayout),
            ],
          ),
        ),
      ],
    );
  }

  Widget _layoutDirectionItemButton(
    BuildContext context,
    LayoutDirection direction,
  ) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_layoutDirectionLabelText(direction)),
        rightIcon: currentLayoutDirection == direction
            ? const FlowySvg(FlowySvgs.check_s)
            : null,
        onTap: () {
          if (currentLayoutDirection != direction) {
            context
                .read<AppearanceSettingsCubit>()
                .setLayoutDirection(direction);
          }
          PopoverContainer.of(context).close();
        },
      ),
    );
  }

  String _layoutDirectionLabelText(LayoutDirection direction) {
    switch (direction) {
      case (LayoutDirection.ltrLayout):
        return LocaleKeys.settings_appearance_layoutDirection_ltr.tr();
      case (LayoutDirection.rtlLayout):
        return LocaleKeys.settings_appearance_layoutDirection_rtl.tr();
      default:
        return '';
    }
  }
}

class TextDirectionSetting extends StatelessWidget {
  const TextDirectionSetting({
    super.key,
    required this.currentTextDirection,
  });

  final AppFlowyTextDirection? currentTextDirection;

  @override
  Widget build(BuildContext context) => FlowySettingListTile(
        label: LocaleKeys.settings_appearance_textDirection_label.tr(),
        hint: LocaleKeys.settings_appearance_textDirection_hint.tr(),
        trailing: [
          FlowySettingValueDropDown(
            currentValue: _textDirectionLabelText(currentTextDirection),
            popupBuilder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textDirectionItemButton(context, null),
                _textDirectionItemButton(context, AppFlowyTextDirection.ltr),
                _textDirectionItemButton(context, AppFlowyTextDirection.rtl),
                _textDirectionItemButton(context, AppFlowyTextDirection.auto),
              ],
            ),
          ),
        ],
      );

  Widget _textDirectionItemButton(
    BuildContext context,
    AppFlowyTextDirection? textDirection,
  ) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_textDirectionLabelText(textDirection)),
        rightIcon: currentTextDirection == textDirection
            ? const FlowySvg(FlowySvgs.check_s)
            : null,
        onTap: () {
          if (currentTextDirection != textDirection) {
            context
                .read<AppearanceSettingsCubit>()
                .setTextDirection(textDirection);
            context
                .read<DocumentAppearanceCubit>()
                .syncDefaultTextDirection(textDirection?.name);
          }
          PopoverContainer.of(context).close();
        },
      ),
    );
  }

  String _textDirectionLabelText(AppFlowyTextDirection? textDirection) {
    switch (textDirection) {
      case (AppFlowyTextDirection.ltr):
        return LocaleKeys.settings_appearance_textDirection_ltr.tr();
      case (AppFlowyTextDirection.rtl):
        return LocaleKeys.settings_appearance_textDirection_rtl.tr();
      case (AppFlowyTextDirection.auto):
        return LocaleKeys.settings_appearance_textDirection_auto.tr();
      default:
        return LocaleKeys.settings_appearance_textDirection_fallback.tr();
    }
  }
}

class EnableRTLToolbarItemsSetting extends StatelessWidget {
  const EnableRTLToolbarItemsSetting({
    super.key,
  });

  static const enableRTLSwitchKey = ValueKey('enable_rtl_toolbar_items_switch');

  @override
  Widget build(BuildContext context) {
    return FlowySettingListTile(
      label: LocaleKeys.settings_appearance_enableRTLToolbarItems.tr(),
      trailing: [
        Switch(
          key: enableRTLSwitchKey,
          value: context
              .read<AppearanceSettingsCubit>()
              .state
              .enableRtlToolbarItems,
          splashRadius: 0,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) {
            context
                .read<AppearanceSettingsCubit>()
                .setEnableRTLToolbarItems(value);
          },
        ),
      ],
    );
  }
}
