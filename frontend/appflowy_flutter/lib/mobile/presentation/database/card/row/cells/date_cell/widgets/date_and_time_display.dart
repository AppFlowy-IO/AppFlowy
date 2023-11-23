import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cal_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateAndTimeDisplay extends StatelessWidget {
  const DateAndTimeDisplay(this.state, {super.key});
  final DateCellCalendarState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // date/start date and time
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DateEditButton(
              dateStr: state.isRange
                  ? _formatDateByDateFormatPB(
                      state.startDay,
                      state.dateTypeOptionPB.dateFormat,
                    )
                  : state.dateStr,
              initialDate: state.isRange ? state.startDay : state.dateTime,
              onDaySelected: (newDate) {
                context.read<DateCellCalendarBloc>().add(
                      state.isRange
                          ? DateCellCalendarEvent.setStartDay(newDate)
                          : DateCellCalendarEvent.selectDay(newDate),
                    );
              },
            ),
            const HSpace(8),
            if (state.includeTime)
              Expanded(child: _TimeEditButton(state.timeStr)),
          ],
        ),
        const VSpace(8),
        // end date and time
        if (state.isRange) ...[
          _DateEditButton(
            dateStr: state.endDay != null ? state.endDateStr : null,
            initialDate: state.endDay,
            onDaySelected: (newDate) {
              context.read<DateCellCalendarBloc>().add(
                    DateCellCalendarEvent.setEndDay(newDate),
                  );
            },
          ),
          const HSpace(8),
          if (state.includeTime)
            Expanded(child: _TimeEditButton(state.endTimeStr)),
        ],
      ],
    );
  }
}

class _DateEditButton extends StatelessWidget {
  const _DateEditButton({
    required this.dateStr,
    required this.initialDate,
    required this.onDaySelected,
  });

  final String? dateStr;

  /// initial date for date picker, if null, use DateTime.now()
  final DateTime? initialDate;
  final void Function(DateTime)? onDaySelected;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      // share space with TimeEditButton
      width: (size.width - 8) / 2,
      child: OutlinedButton(
        onPressed: () async {
          final DateTime? newDate = await showDatePicker(
            context: context,
            initialDate: initialDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (newDate != null) {
            onDaySelected?.call(newDate);
          }
        },
        child: Text(
          dateStr ?? LocaleKeys.grid_field_selectDate.tr(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _TimeEditButton extends StatelessWidget {
  const _TimeEditButton(
    this.timeStr,
  );

  final String? timeStr;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      // TODO(yijing): implement time picker
      onPressed: null,
      child: Text(
        timeStr ?? LocaleKeys.grid_field_selectTime.tr(),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

String? _formatDateByDateFormatPB(DateTime? date, DateFormatPB dateFormatPB) {
  if (date == null) {
    return null;
  }
  switch (dateFormatPB) {
    case DateFormatPB.Local:
      return DateFormat('MM/dd/yyyy').format(date);
    case DateFormatPB.US:
      return DateFormat('yyyy/MM/dd').format(date);
    case DateFormatPB.ISO:
      return DateFormat('yyyy-MM-dd').format(date);
    case DateFormatPB.Friendly:
      return DateFormat('MMM dd, yyyy').format(date);
    case DateFormatPB.DayMonthYear:
      return DateFormat('dd/MM/yyyy').format(date);
    default:
      return 'Unavailable date format';
  }
}
