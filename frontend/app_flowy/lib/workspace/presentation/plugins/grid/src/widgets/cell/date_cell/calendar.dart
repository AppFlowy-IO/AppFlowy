import 'package:app_flowy/workspace/application/grid/cell/date_cal_bloc.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class CellCalendar with FlowyOverlayDelegate {
  final VoidCallback onDismissed;

  const CellCalendar({
    required this.onDismissed,
  });

  Future<void> show(
    BuildContext context, {
    required GridDefaultCellContext cellContext,
    required void Function(DateTime) onSelected,
  }) async {
    CellCalendar.remove(context);

    final calendar = _CellCalendarWidget(
      onSelected: onSelected,
      includeTime: false,
      cellContext: cellContext,
    );
    // const size = Size(460, 400);
    // final window = await getWindowInfo();
    // FlowyOverlay.of(context).insertWithRect(
    //   widget: OverlayContainer(
    //     child: calendar,
    //     constraints: BoxConstraints.loose(const Size(460, 400)),
    //   ),
    //   identifier: _CellCalendar.identifier(),
    //   anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
    //   anchorSize: window.frame.size,
    //   anchorDirection: AnchorDirection.center,
    //   style: FlowyOverlayStyle(blur: false),
    //   delegate: calendar,
    // );

    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: calendar,
        constraints: BoxConstraints.tight(const Size(320, 320)),
      ),
      identifier: CellCalendar.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  static void remove(BuildContext context) {
    FlowyOverlay.of(context).remove(identifier());
  }

  static String identifier() {
    return (CellCalendar).toString();
  }

  @override
  void didRemove() => onDismissed();
}

class _CellCalendarWidget extends StatelessWidget {
  final bool includeTime;
  final GridDefaultCellContext cellContext;
  final void Function(DateTime) onSelected;

  const _CellCalendarWidget({
    required this.onSelected,
    required this.includeTime,
    required this.cellContext,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider(
      create: (context) => DateCalBloc(cellContext: cellContext)..add(const DateCalEvent.initial()),
      child: BlocConsumer<DateCalBloc, DateCalState>(
        listener: (context, state) {
          if (state.selectedDay != null) {
            onSelected(state.selectedDay!);
          }
        },
        listenWhen: (p, c) => p.selectedDay != c.selectedDay,
        builder: (context, state) {
          return TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: state.focusedDay,
            rowHeight: 40,
            calendarFormat: state.format,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: theme.main1,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.shader4,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: theme.surface,
                fontSize: 14.0,
              ),
              todayTextStyle: TextStyle(
                color: theme.surface,
                fontSize: 14.0,
              ),
            ),
            selectedDayPredicate: (day) {
              return isSameDay(state.selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              context.read<DateCalBloc>().add(DateCalEvent.selectDay(selectedDay));
            },
            onFormatChanged: (format) {
              context.read<DateCalBloc>().add(DateCalEvent.setFormat(format));
            },
            onPageChanged: (focusedDay) {
              context.read<DateCalBloc>().add(DateCalEvent.setFocusedDay(focusedDay));
            },
          );
        },
      ),
    );
  }
}
