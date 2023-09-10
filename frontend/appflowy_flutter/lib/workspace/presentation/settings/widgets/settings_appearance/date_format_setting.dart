import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_setting_entry_template.dart';

class DateFormatSetting extends StatelessWidget {
  const DateFormatSetting({
    super.key,
    required this.currentFormat,
  });

  final DateFormatPB currentFormat;

  @override
  Widget build(BuildContext context) => ThemeSettingEntryTemplateWidget(
        label: LocaleKeys.settings_appearance_dateFormat_label.tr(),
        // onResetRequested:
        //     context.read<AppearanceSettingsCubit>().resetThemeMode,
        trailing: [
          ThemeValueDropDown(
            currentValue: _formatLabel(currentFormat),
            popupBuilder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formatItem(context, DateFormatPB.Locally),
                _formatItem(context, DateFormatPB.US),
                _formatItem(context, DateFormatPB.ISO),
                _formatItem(context, DateFormatPB.Friendly),
                _formatItem(context, DateFormatPB.DayMonthYear),
              ],
            ),
          ),
        ],
      );

  Widget _formatItem(BuildContext context, DateFormatPB format) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_formatLabel(format)),
        rightIcon: currentFormat == format
            ? const FlowySvg(
                FlowySvgs.check_s,
              )
            : null,
        onTap: () {
          if (currentFormat != format) {
            context.read<AppearanceSettingsCubit>().setDateFormat(format);
          }
        },
      ),
    );
  }

  String _formatLabel(DateFormatPB format) {
    switch (format) {
      case (DateFormatPB.Locally):
        return LocaleKeys.settings_appearance_dateFormat_local.tr();
      case (DateFormatPB.US):
        return LocaleKeys.settings_appearance_dateFormat_us.tr();
      case (DateFormatPB.ISO):
        return LocaleKeys.settings_appearance_dateFormat_iso.tr();
      case (DateFormatPB.Friendly):
        return LocaleKeys.settings_appearance_dateFormat_friendly.tr();
      case (DateFormatPB.DayMonthYear):
        return LocaleKeys.settings_appearance_dateFormat_dmy.tr();
      default:
        return "";
    }
  }
}
