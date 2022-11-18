import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/cell/date_cal_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:app_flowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';
import '../../../layout/sizes.dart';
import '../../header/type_option/date.dart';

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
const kMargin = EdgeInsets.symmetric(horizontal: 6, vertical: 10);

class DateCellEditor extends StatefulWidget {
  final VoidCallback onDismissed;
  final GridDateCellController cellController;

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
      future: widget.cellController.getFieldTypeOption(
        DateTypeOptionDataParser(),
      ),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return _buildWidget(snapshot);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildWidget(AsyncSnapshot<Either<dynamic, FlowyError>> snapshot) {
    return snapshot.data!.fold(
      (dateTypeOptionPB) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: _CellCalendarWidget(
            cellContext: widget.cellController,
            dateTypeOptionPB: dateTypeOptionPB,
          ),
        );
      },
      (err) {
        Log.error(err);
        return const SizedBox();
      },
    );
  }
}

class _CellCalendarWidget extends StatefulWidget {
  final GridDateCellController cellContext;
  final DateTypeOptionPB dateTypeOptionPB;

  const _CellCalendarWidget({
    required this.cellContext,
    required this.dateTypeOptionPB,
    Key? key,
  }) : super(key: key);

  @override
  State<_CellCalendarWidget> createState() => _CellCalendarWidgetState();
}

class _CellCalendarWidgetState extends State<_CellCalendarWidget> {
  late PopoverMutex popoverMutex;
  late DateCalBloc bloc;

  @override
  void initState() {
    popoverMutex = PopoverMutex();

    bloc = DateCalBloc(
      dateTypeOptionPB: widget.dateTypeOptionPB,
      cellData: widget.cellContext.getCellData(),
      cellController: widget.cellContext,
    )..add(const DateCalEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<DateCalBloc, DateCalState>(
        buildWhen: (p, c) => false,
        builder: (context, state) {
          List<Widget> children = [
            _buildCalendar(context),
            _TimeTextField(
              bloc: context.read<DateCalBloc>(),
              popoverMutex: popoverMutex,
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const _IncludeTimeButton(),
            _DateTypeOptionButton(popoverMutex: popoverMutex)
          ];

          return ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            separatorBuilder: (context, index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
            itemCount: children.length,
            itemBuilder: (BuildContext context, int index) {
              return children[index];
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    bloc.close();
    popoverMutex.dispose();
    super.dispose();
  }

  Widget _buildCalendar(BuildContext context) {
    return BlocBuilder<DateCalBloc, DateCalState>(
      builder: (context, state) {
        return TableCalendar(
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: state.focusedDay,
          rowHeight: 40,
          calendarFormat: state.format,
          daysOfWeekHeight: 40,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyles.body1.size(FontSizes.s14),
            leftChevronMargin: EdgeInsets.zero,
            leftChevronPadding: EdgeInsets.zero,
            leftChevronIcon: svgWidget("home/arrow_left"),
            rightChevronPadding: EdgeInsets.zero,
            rightChevronMargin: EdgeInsets.zero,
            rightChevronIcon: svgWidget("home/arrow_right"),
            headerMargin: const EdgeInsets.only(bottom: 8.0),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) =>
                DateFormat.E(locale).format(date).toUpperCase(),
            weekdayStyle: TextStyles.general(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).hintColor,
            ),
            weekendStyle: TextStyles.general(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).hintColor,
            ),
          ),
          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(3),
            defaultDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            todayDecoration: BoxDecoration(
              color: AFThemeExtension.of(context).lightGreyHover,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            weekendDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            outsideDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            defaultTextStyle: TextStyles.body1.size(FontSizes.s14),
            weekendTextStyle: TextStyles.body1.size(FontSizes.s14),
            selectedTextStyle: TextStyles.general(
              fontSize: FontSizes.s14,
              color: Theme.of(context).colorScheme.surface,
            ),
            todayTextStyle: TextStyles.general(
              fontSize: FontSizes.s14,
            ),
            outsideTextStyle: TextStyles.general(
              fontSize: FontSizes.s14,
              color: Theme.of(context).disabledColor,
            ),
          ),
          selectedDayPredicate: (day) {
            return state.calData.fold(
              () => false,
              (dateData) => isSameDay(dateData.date, day),
            );
          },
          onDaySelected: (selectedDay, focusedDay) {
            context
                .read<DateCalBloc>()
                .add(DateCalEvent.selectDay(selectedDay));
          },
          onFormatChanged: (format) {
            context.read<DateCalBloc>().add(DateCalEvent.setCalFormat(format));
          },
          onPageChanged: (focusedDay) {
            context
                .read<DateCalBloc>()
                .add(DateCalEvent.setFocusedDay(focusedDay));
          },
        );
      },
    );
  }
}

class _IncludeTimeButton extends StatelessWidget {
  const _IncludeTimeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCalBloc, DateCalState, bool>(
      selector: (state) => state.dateTypeOptionPB.includeTime,
      builder: (context, includeTime) {
        return SizedBox(
          height: 50,
          child: Padding(
            padding: kMargin,
            child: Row(
              children: [
                svgWidget(
                  "grid/clock",
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const HSpace(4),
                FlowyText.medium(
                  LocaleKeys.grid_field_includeTime.tr(),
                  fontSize: FontSizes.s14,
                ),
                const Spacer(),
                Toggle(
                  value: includeTime,
                  onChanged: (value) => context
                      .read<DateCalBloc>()
                      .add(DateCalEvent.setIncludeTime(!value)),
                  style: ToggleStyle.big,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimeTextField extends StatefulWidget {
  final DateCalBloc bloc;
  final PopoverMutex popoverMutex;
  const _TimeTextField({
    required this.bloc,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_TimeTextField> createState() => _TimeTextFieldState();
}

class _TimeTextFieldState extends State<_TimeTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.bloc.state.time);
    if (widget.bloc.state.dateTypeOptionPB.includeTime) {
      _focusNode.addListener(() {
        if (mounted) {
          widget.bloc.add(DateCalEvent.setTime(_controller.text));
        }

        if (_focusNode.hasFocus) {
          widget.popoverMutex.close();
        }
      });

      widget.popoverMutex.listenOnPopoverChanged(() {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DateCalBloc, DateCalState>(
      listener: (context, state) {
        _controller.text = state.time ?? "";
      },
      listenWhen: (p, c) => p.time != c.time,
      builder: (context, state) {
        if (state.dateTypeOptionPB.includeTime) {
          return Padding(
            padding: kMargin,
            child: RoundedInputField(
              height: 40,
              focusNode: _focusNode,
              autoFocus: true,
              hintText: state.timeHintText,
              controller: _controller,
              style: TextStyles.body1.size(FontSizes.s14),
              normalBorderColor: Theme.of(context).colorScheme.outline,
              errorBorderColor: Theme.of(context).colorScheme.error,
              focusBorderColor: Theme.of(context).colorScheme.primary,
              cursorColor: Theme.of(context).colorScheme.primary,
              errorText: state.timeFormatError.fold(() => "", (error) => error),
              onEditingComplete: (value) {
                widget.bloc.add(DateCalEvent.setTime(value));
              },
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
}

class _DateTypeOptionButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  const _DateTypeOptionButton({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title =
        "${LocaleKeys.grid_field_dateFormat.tr()} &${LocaleKeys.grid_field_timeFormat.tr()}";
    return BlocSelector<DateCalBloc, DateCalState, DateTypeOptionPB>(
      selector: (state) => state.dateTypeOptionPB,
      builder: (context, dateTypeOptionPB) {
        return AppFlowyPopover(
          mutex: popoverMutex,
          triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
          offset: const Offset(20, 0),
          constraints: BoxConstraints.loose(const Size(140, 100)),
          child: FlowyButton(
            text: FlowyText.medium(title, fontSize: 14),
            margin: kMargin,
            rightIcon: svgWidget(
              "grid/more",
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          popupBuilder: (BuildContext popContext) {
            return _CalDateTimeSetting(
              dateTypeOptionPB: dateTypeOptionPB,
              onEvent: (event) {
                context.read<DateCalBloc>().add(event);
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
  final Function(DateCalEvent) onEvent;
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
    List<Widget> children = [
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(20, 0),
        popupBuilder: (BuildContext context) {
          return DateFormatList(
            selectedFormat: widget.dateTypeOptionPB.dateFormat,
            onSelected: (format) {
              widget.onEvent(DateCalEvent.setDateFormat(format));
              timeSettingPopoverMutex.close();
            },
          );
        },
        child: const DateFormatButton(),
      ),
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(20, 0),
        popupBuilder: (BuildContext context) {
          return TimeFormatList(
              selectedFormat: widget.dateTypeOptionPB.timeFormat,
              onSelected: (format) {
                widget.onEvent(DateCalEvent.setTimeFormat(format));
                timeSettingPopoverMutex.close();
              });
        },
        child: TimeFormatButton(timeFormat: widget.dateTypeOptionPB.timeFormat),
      ),
    ];

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) {
          return children[index];
        },
      ),
    );
  }
}
