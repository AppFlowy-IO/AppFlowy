import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:window_size/window_size.dart';

class DateCell extends StatefulWidget {
  final CellData cellData;

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
              onTap: () => _CellCalendar.show(
                context,
                onSelected: (day) => context.read<DateCellBloc>().add(DateCellEvent.selectDay(day)),
              ),
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

class _CellCalendar extends StatefulWidget {
  final void Function(DateTime) onSelected;
  const _CellCalendar({required this.onSelected, Key? key}) : super(key: key);

  @override
  State<_CellCalendar> createState() => _CellCalendarState();

  static Future<void> show(BuildContext context, {required void Function(DateTime) onSelected}) async {
    _CellCalendar.remove(context);
    final window = await getWindowInfo();
    final calendar = _CellCalendar(onSelected: onSelected);
    const size = Size(460, 400);
    FlowyOverlay.of(context).insertWithRect(
      widget: OverlayContainer(
        child: calendar,
        constraints: BoxConstraints.loose(const Size(460, 400)),
      ),
      identifier: _CellCalendar.identifier(),
      anchorPosition: Offset(-size.width / 2.0, -size.height / 2.0),
      anchorSize: window.frame.size,
      anchorDirection: AnchorDirection.center,
      style: FlowyOverlayStyle(blur: false),
    );
  }

  static void remove(BuildContext context) {
    FlowyOverlay.of(context).remove(identifier());
  }

  static String identifier() {
    return (_CellCalendar).toString();
  }
}

class _CellCalendarState extends State<_CellCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      headerStyle: const HeaderStyle(formatButtonVisible: false),
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
