import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/cell/cell_container.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

class DateCell extends GridCellWidget {
  final GridCell cellData;

  const DateCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<DateCellBloc>(param1: widget.cellData)..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget.setFocus(context, true);
                _CellCalendar.show(
                  context,
                  onSelected: (day) {
                    context.read<DateCellBloc>().add(DateCellEvent.selectDay(day));
                  },
                  onDismissed: () => widget.setFocus(context, false),
                );
              },
              child: MouseRegion(
                opaque: false,
                cursor: SystemMouseCursors.click,
                child: Center(child: FlowyText.medium(state.content, fontSize: 12)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class _CellCalendar extends StatefulWidget with FlowyOverlayDelegate {
  final void Function(DateTime) onSelected;
  final VoidCallback onDismissed;
  final bool includeTime;
  const _CellCalendar({
    required this.onSelected,
    required this.onDismissed,
    required this.includeTime,
    Key? key,
  }) : super(key: key);

  @override
  State<_CellCalendar> createState() => _CellCalendarState();

  static Future<void> show(
    BuildContext context, {
    required void Function(DateTime) onSelected,
    required VoidCallback onDismissed,
  }) async {
    _CellCalendar.remove(context);

    final calendar = _CellCalendar(
      onSelected: onSelected,
      onDismissed: onDismissed,
      includeTime: false,
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
      identifier: _CellCalendar.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      delegate: calendar,
    );
  }

  static void remove(BuildContext context) {
    FlowyOverlay.of(context).remove(identifier());
  }

  static String identifier() {
    return (_CellCalendar).toString();
  }

  @override
  void didRemove() => onDismissed();
}

class _CellCalendarState extends State<_CellCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return TableCalendar(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: _focusedDay,
      rowHeight: 40,
      calendarFormat: _calendarFormat,
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
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          // Call `setState()` when updating the selected day
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            widget.onSelected(selectedDay);
          });
        }
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }
}
