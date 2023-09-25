import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/timestamp.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/time/prelude.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../../../grid/presentation/widgets/common/type_option_separator.dart';
import '../../../../grid/presentation/widgets/header/type_option/date.dart';
import 'date_cal_bloc.dart';

class DateCellEditor extends StatefulWidget {
  final VoidCallback onDismissed;
  final DateCellController cellController;

  const DateCellEditor({
    Key? key,
    required this.onDismissed,
    required this.cellController,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DateCellEditor();
}

class _DateCellEditor extends State<DateCellEditor> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<dynamic, FlowyError>>(
      future: widget.cellController.getTypeOption(
        DateTypeOptionDataParser(),
      ),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return _buildWidget(snapshot);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWidget(AsyncSnapshot<Either<dynamic, FlowyError>> snapshot) {
    return snapshot.data!.fold(
      (dateTypeOptionPB) {
        return _CellCalendarWidget(
          cellContext: widget.cellController,
          dateTypeOptionPB: dateTypeOptionPB,
        );
      },
      (err) {
        Log.error(err);
        return const SizedBox.shrink();
      },
    );
  }
}

class _CellCalendarWidget extends StatefulWidget {
  final DateCellController cellContext;
  final DateTypeOptionPB dateTypeOptionPB;

  const _CellCalendarWidget({
    required this.cellContext,
    required this.dateTypeOptionPB,
  });

  @override
  State<_CellCalendarWidget> createState() => _CellCalendarWidgetState();
}

class _CellCalendarWidgetState extends State<_CellCalendarWidget> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellCalendarBloc(
        dateTypeOptionPB: widget.dateTypeOptionPB,
        cellData: widget.cellContext.getCellData(),
        cellController: widget.cellContext,
      )..add(const DateCellCalendarEvent.initial()),
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StartTextField(popoverMutex: popoverMutex),
            EndTextField(popoverMutex: popoverMutex),
            const DatePicker(),
            const TypeOptionSeparator(spacing: 12.0),
            const EndTimeButton(),
            const VSpace(4.0),
            const _IncludeTimeButton(),
            const TypeOptionSeparator(spacing: 8.0),
            DateTypeOptionButton(popoverMutex: popoverMutex),
            const VSpace(4.0),
            const ClearDateButton(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }
}

class StartTextField extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const StartTextField({super.key, required this.popoverMutex});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.includeTime
              ? _TimeTextField(
                  isEndTime: false,
                  timeStr: state.time,
                  popoverMutex: popoverMutex,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class EndTextField extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const EndTextField({super.key, required this.popoverMutex});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.includeTime && state.isRange
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _TimeTextField(
                    isEndTime: true,
                    timeStr: state.endTime,
                    popoverMutex: popoverMutex,
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class DatePicker extends StatefulWidget {
  const DatePicker({super.key});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        final textStyle = Theme.of(context).textTheme.bodyMedium!;
        final boxDecoration = BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            rowHeight: 26.0 + 7.0,
            calendarFormat: _calendarFormat,
            daysOfWeekHeight: 17.0 + 8.0,
            rangeSelectionMode: state.isRange
                ? RangeSelectionMode.enforced
                : RangeSelectionMode.disabled,
            rangeStartDay: state.isRange ? state.startDay : null,
            rangeEndDay: state.isRange ? state.endDay : null,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: textStyle,
              leftChevronMargin: EdgeInsets.zero,
              leftChevronPadding: EdgeInsets.zero,
              leftChevronIcon: FlowySvg(
                FlowySvgs.arrow_left_s,
                color: Theme.of(context).iconTheme.color,
              ),
              rightChevronPadding: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
              rightChevronIcon: FlowySvg(
                FlowySvgs.arrow_right_s,
                color: Theme.of(context).iconTheme.color,
              ),
              headerMargin: EdgeInsets.zero,
              headerPadding: const EdgeInsets.only(bottom: 8.0),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(3.5),
              defaultDecoration: boxDecoration,
              selectedDecoration: boxDecoration.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              todayDecoration: boxDecoration.copyWith(
                color: Colors.transparent,
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              weekendDecoration: boxDecoration,
              outsideDecoration: boxDecoration,
              rangeStartDecoration: boxDecoration.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              rangeEndDecoration: boxDecoration.copyWith(
                color: Theme.of(context).colorScheme.primary,
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
                      style: AFThemeExtension.of(context).caption,
                    ),
                  ),
                );
              },
            ),
            selectedDayPredicate: (day) =>
                state.isRange ? false : isSameDay(state.dateTime, day),
            onDaySelected: (selectedDay, focusedDay) {
              context.read<DateCellCalendarBloc>().add(
                    DateCellCalendarEvent.selectDay(selectedDay.toLocal().date),
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
            }),
          ),
        );
      },
    );
  }
}

class _IncludeTimeButton extends StatelessWidget {
  const _IncludeTimeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState, bool>(
      selector: (state) => state.includeTime,
      builder: (context, includeTime) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: IncludeTimeButton(
            onChanged: (value) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setIncludeTime(!value)),
            value: includeTime,
          ),
        );
      },
    );
  }
}

@visibleForTesting
class EndTimeButton extends StatelessWidget {
  const EndTimeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState, bool>(
      selector: (state) => state.isRange,
      builder: (context, isRange) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: Padding(
              padding: GridSize.typeOptionContentInsets,
              child: Row(
                children: [
                  FlowySvg(
                    FlowySvgs.date_s,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const HSpace(6),
                  FlowyText.medium(LocaleKeys.grid_field_isRange.tr()),
                  const Spacer(),
                  Toggle(
                    value: isRange,
                    onChanged: (value) => context
                        .read<DateCellCalendarBloc>()
                        .add(DateCellCalendarEvent.setIsRange(!value)),
                    style: ToggleStyle.big,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeTextField extends StatefulWidget {
  final bool isEndTime;
  final String? timeStr;
  final PopoverMutex popoverMutex;

  const _TimeTextField({
    required this.timeStr,
    required this.popoverMutex,
    required this.isEndTime,
  });

  @override
  State<_TimeTextField> createState() => _TimeTextFieldState();
}

class _TimeTextFieldState extends State<_TimeTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textController;

  @override
  void initState() {
    _focusNode = FocusNode();
    _textController = TextEditingController()..text = widget.timeStr ?? "";

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.popoverMutex.close();
      }
    });

    widget.popoverMutex.listenOnPopoverChanged(() {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DateCellCalendarBloc, DateCellCalendarState>(
      listener: (context, state) {
        if (widget.isEndTime) {
          _textController.text = state.endTime ?? "";
        } else {
          _textController.text = state.time ?? "";
        }
      },
      builder: (context, state) {
        String text = "";
        if (!widget.isEndTime && state.time != null) {
          text = state.time!;
        } else if (state.endTime != null) {
          text = state.endTime!;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: FlowyTextField(
            text: text,
            focusNode: _focusNode,
            controller: _textController,
            submitOnLeave: true,
            hintText: state.timeHintText,
            errorText: widget.isEndTime
                ? state.parseEndTimeError
                : state.parseTimeError,
            onSubmitted: (timeStr) {
              if (widget.isEndTime) {
                context
                    .read<DateCellCalendarBloc>()
                    .add(DateCellCalendarEvent.setEndTime(timeStr));
              } else {
                context
                    .read<DateCellCalendarBloc>()
                    .add(DateCellCalendarEvent.setTime(timeStr));
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(() {
      if (_focusNode.hasFocus) {
        widget.popoverMutex.close();
      }
    });
    _focusNode.dispose();
    super.dispose();
  }
}

@visibleForTesting
class DateTypeOptionButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const DateTypeOptionButton({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title =
        "${LocaleKeys.grid_field_dateFormat.tr()} & ${LocaleKeys.grid_field_timeFormat.tr()}";
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState,
        DateTypeOptionPB>(
      selector: (state) => state.dateTypeOptionPB,
      builder: (context, dateTypeOptionPB) {
        return AppFlowyPopover(
          mutex: popoverMutex,
          triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
          offset: const Offset(8, 0),
          margin: EdgeInsets.zero,
          constraints: BoxConstraints.loose(const Size(140, 100)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              height: GridSize.popoverItemHeight,
              child: FlowyButton(
                text: FlowyText.medium(title),
                rightIcon: const FlowySvg(FlowySvgs.more_s),
              ),
            ),
          ),
          popupBuilder: (BuildContext popContext) {
            return _CalDateTimeSetting(
              dateTypeOptionPB: dateTypeOptionPB,
              onEvent: (event) {
                context.read<DateCellCalendarBloc>().add(event);
                popoverMutex.close();
              },
            );
          },
        );
      },
    );
  }
}

class _CalDateTimeSetting extends StatefulWidget {
  final DateTypeOptionPB dateTypeOptionPB;
  final Function(DateCellCalendarEvent) onEvent;
  const _CalDateTimeSetting({
    required this.dateTypeOptionPB,
    required this.onEvent,
    Key? key,
  }) : super(key: key);

  @override
  State<_CalDateTimeSetting> createState() => _CalDateTimeSettingState();
}

class _CalDateTimeSettingState extends State<_CalDateTimeSetting> {
  final timeSettingPopoverMutex = PopoverMutex();
  String? overlayIdentifier;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(8, 0),
        popupBuilder: (BuildContext context) {
          return DateFormatList(
            selectedFormat: widget.dateTypeOptionPB.dateFormat,
            onSelected: (format) {
              widget.onEvent(DateCellCalendarEvent.setDateFormat(format));
              timeSettingPopoverMutex.close();
            },
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: DateFormatButton(),
        ),
      ),
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(8, 0),
        popupBuilder: (BuildContext context) {
          return TimeFormatList(
            selectedFormat: widget.dateTypeOptionPB.timeFormat,
            onSelected: (format) {
              widget.onEvent(DateCellCalendarEvent.setTimeFormat(format));
              timeSettingPopoverMutex.close();
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child:
              TimeFormatButton(timeFormat: widget.dateTypeOptionPB.timeFormat),
        ),
      ),
    ];

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) =>
            VSpace(GridSize.typeOptionSeparatorHeight),
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => children[index],
        padding: const EdgeInsets.symmetric(vertical: 6.0),
      ),
    );
  }
}

@visibleForTesting
class ClearDateButton extends StatelessWidget {
  const ClearDateButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          text: FlowyText.medium(LocaleKeys.grid_field_clearDate.tr()),
          onTap: () {
            context
                .read<DateCellCalendarBloc>()
                .add(const DateCellCalendarEvent.clearDate());
            PopoverContainer.of(context).close();
          },
        ),
      ),
    );
  }
}
