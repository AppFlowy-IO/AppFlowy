import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import 'date_cal_bloc.dart';

class MobileDatePicker extends StatefulWidget {
  const MobileDatePicker({
    super.key,
  });

  @override
  State<MobileDatePicker> createState() => _MobileDatePickerState();
}

class _MobileDatePickerState extends State<MobileDatePicker> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final ValueNotifier<(DateTime, dynamic)> _currentDateNotifier = ValueNotifier(
    (DateTime.now(), null),
  );
  PageController? _pageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(8.0),
        _buildHeader(context),
        const VSpace(8.0),
        _buildCalendar(context),
        const VSpace(16.0),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    const selectedColor = Color(0xFF00BCF0);
    final textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith();
    const boxDecoration = BoxDecoration(
      shape: BoxShape.circle,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
        builder: (context, state) {
          return TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            rowHeight: 48.0,
            calendarFormat: _calendarFormat,
            daysOfWeekHeight: 48.0,
            rangeSelectionMode: state.isRange
                ? RangeSelectionMode.enforced
                : RangeSelectionMode.disabled,
            rangeStartDay: state.isRange ? state.startDay : null,
            rangeEndDay: state.isRange ? state.endDay : null,
            onCalendarCreated: (pageController) =>
                _pageController = pageController,
            headerVisible: false,
            availableGestures: AvailableGestures.horizontalSwipe,
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(3.5),
              defaultDecoration: boxDecoration,
              selectedDecoration: boxDecoration.copyWith(
                color: selectedColor,
              ),
              todayDecoration: boxDecoration.copyWith(
                color: Colors.transparent,
                border: Border.all(color: selectedColor),
              ),
              weekendDecoration: boxDecoration,
              outsideDecoration: boxDecoration,
              rangeStartDecoration: boxDecoration.copyWith(
                color: selectedColor,
              ),
              rangeEndDecoration: boxDecoration.copyWith(
                color: selectedColor,
              ),
              defaultTextStyle: textStyle,
              weekendTextStyle: textStyle,
              selectedTextStyle: textStyle.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
              rangeStartTextStyle: textStyle.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
              rangeEndTextStyle: textStyle.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
              todayTextStyle: textStyle,
              outsideTextStyle: textStyle.copyWith(
                color: Theme.of(context).disabledColor,
              ),
              rangeHighlightColor:
                  Theme.of(context).colorScheme.secondaryContainer,
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final locale = context.locale.toLanguageTag();
                final label = DateFormat.E(locale).format(day).substring(0, 2);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Center(
                    child: Text(
                      label,
                      style: textStyle.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                );
              },
            ),
            selectedDayPredicate: (day) =>
                state.isRange ? false : isSameDay(state.dateTime, day),
            onDaySelected: (selectedDay, focusedDay) {
              context.read<DateCellCalendarBloc>().add(
                    DateCellCalendarEvent.selectDay(selectedDay),
                  );
            },
            onRangeSelected: (start, end, focusedDay) {
              context.read<DateCellCalendarBloc>().add(
                    DateCellCalendarEvent.selectDateRange(start, end),
                  );
            },
            onFormatChanged: (calendarFormat) => setState(() {
              _calendarFormat = calendarFormat;
            }),
            onPageChanged: (focusedDay) => setState(() {
              _focusedDay = focusedDay;
              _currentDateNotifier.value = (focusedDay, null);
            }),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const HSpace(16.0),
        ValueListenableBuilder(
          valueListenable: _currentDateNotifier,
          builder: (_, value, ___) {
            return FlowyText(
              DateFormat.yMMMM(value.$2).format(value.$1),
            );
          },
        ),
        const Spacer(),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(24.0),
          ),
          onTap: () => _pageController?.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ),
        const HSpace(24.0),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(
            FlowySvgs.arrow_right_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(24.0),
          ),
          onTap: () => _pageController?.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ),
        const HSpace(8.0),
      ],
    );
  }
}
