import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cal_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateFormatOption extends StatelessWidget {
  const DateFormatOption({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return Row(
      children: [
        Text(
          LocaleKeys.grid_field_dateFormat.tr(),
          style: style.textTheme.titleMedium,
        ),
        const Spacer(),
        BlocSelector<DateCellCalendarBloc, DateCellCalendarState,
            DateTypeOptionPB>(
          selector: (state) => state.dateTypeOptionPB,
          builder: (context, state) {
            return GestureDetector(
              child: Row(
                children: [
                  Text(
                    state.dateFormat.title(),
                    style: style.textTheme.titleMedium,
                  ),
                  const HSpace(4),
                  Icon(
                    Icons.arrow_forward_ios_sharp,
                    color: style.hintColor,
                  ),
                ],
              ),
              onTap: () => showFlowyMobileBottomSheet(
                context,
                title: LocaleKeys.grid_field_dateFormat.tr(),
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<DateCellCalendarBloc>(),
                    child: Column(
                      children: [
                        _DateFormatRadioListTile(
                          title: LocaleKeys.grid_field_dateFormatLocal.tr(),
                          dateFormatPB: DateFormatPB.Local,
                        ),
                        _DateFormatRadioListTile(
                          title: LocaleKeys.grid_field_dateFormatUS.tr(),
                          dateFormatPB: DateFormatPB.US,
                        ),
                        _DateFormatRadioListTile(
                          title: LocaleKeys.grid_field_dateFormatISO.tr(),
                          dateFormatPB: DateFormatPB.ISO,
                        ),
                        _DateFormatRadioListTile(
                          title: LocaleKeys.grid_field_dateFormatFriendly.tr(),
                          dateFormatPB: DateFormatPB.Friendly,
                        ),
                        _DateFormatRadioListTile(
                          title:
                              LocaleKeys.grid_field_dateFormatDayMonthYear.tr(),
                          dateFormatPB: DateFormatPB.DayMonthYear,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DateFormatRadioListTile extends StatelessWidget {
  const _DateFormatRadioListTile({
    super.key,
    required this.title,
    required this.dateFormatPB,
  });

  final String title;
  final DateFormatPB dateFormatPB;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return RadioListTile<DateFormatPB>(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        title,
        style: style.textTheme.bodyMedium?.copyWith(
          color: style.colorScheme.onSurface,
        ),
      ),
      groupValue: context
          .watch<DateCellCalendarBloc>()
          .state
          .dateTypeOptionPB
          .dateFormat,
      value: dateFormatPB,
      onChanged: (format) {
        if (format == null) return;
        context
            .read<DateCellCalendarBloc>()
            .add(DateCellCalendarEvent.setDateFormat(format));
      },
    );
  }
}
