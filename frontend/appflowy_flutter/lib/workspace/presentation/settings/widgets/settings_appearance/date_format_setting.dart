import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
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

  final UserDateFormatPB currentFormat;

  @override
  Widget build(BuildContext context) => FlowySettingListTile(
        label: LocaleKeys.settings_appearance_dateFormat_label.tr(),
        trailing: [
          FlowySettingValueDropDown(
            currentValue: _formatLabel(currentFormat),
            popupBuilder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formatItem(context, UserDateFormatPB.Locally),
                _formatItem(context, UserDateFormatPB.US),
                _formatItem(context, UserDateFormatPB.ISO),
                _formatItem(context, UserDateFormatPB.Friendly),
                _formatItem(context, UserDateFormatPB.DayMonthYear),
              ],
            ),
          ),
        ],
      );

  Widget _formatItem(BuildContext context, UserDateFormatPB format) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_formatLabel(format)),
        rightIcon:
            currentFormat == format ? const FlowySvg(FlowySvgs.check_s) : null,
        onTap: () {
          if (currentFormat != format) {
            context.read<AppearanceSettingsCubit>().setDateFormat(format);
          }
        },
      ),
    );
  }

  String _formatLabel(UserDateFormatPB format) {
    switch (format) {
      case (UserDateFormatPB.Locally):
        return LocaleKeys.settings_appearance_dateFormat_local.tr();
      case (UserDateFormatPB.US):
        return LocaleKeys.settings_appearance_dateFormat_us.tr();
      case (UserDateFormatPB.ISO):
        return LocaleKeys.settings_appearance_dateFormat_iso.tr();
      case (UserDateFormatPB.Friendly):
        return LocaleKeys.settings_appearance_dateFormat_friendly.tr();
      case (UserDateFormatPB.DayMonthYear):
        return LocaleKeys.settings_appearance_dateFormat_dmy.tr();
      default:
        return "";
    }
  }
}
