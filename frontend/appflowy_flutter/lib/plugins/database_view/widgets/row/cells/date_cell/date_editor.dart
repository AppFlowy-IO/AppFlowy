import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        return const SizedBox();
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
    Key? key,
  }) : super(key: key);

  @override
  State<_CellCalendarWidget> createState() => _CellCalendarWidgetState();
}

class _CellCalendarWidgetState extends State<_CellCalendarWidget> {
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellCalendarBloc(
        dateTypeOptionPB: widget.dateTypeOptionPB,
        cellData: widget.cellContext.getCellData(),
        cellController: widget.cellContext,
      )..add(const DateCellCalendarEvent.initial()),
      child: BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
        builder: (context, state) {
          final List<Widget> children = [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildCalendar(context),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.includeTime
                  ? _TimeTextField(
                      timeStr: state.time,
                      popoverMutex: popoverMutex,
                    )
                  : const SizedBox.shrink(),
            ),
            const TypeOptionSeparator(spacing: 12.0),
            const _IncludeTimeButton(),
            const TypeOptionSeparator(spacing: 12.0),
            DateTypeOptionButton(popoverMutex: popoverMutex),
            const TypeOptionSeparator(spacing: 12.0),
            const ClearDateButton(),
          ];

          return ListView.builder(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: children.length,
            itemBuilder: (BuildContext context, int index) => children[index],
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  Widget _buildCalendar(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        return AppFlowyCalendar(
          selectedDate: state.dateTime,
          focusedDay: state.focusedDay,
          format: state.format,
          onDaySelected: (selectedDay, focusedDay, _) => context
              .read<DateCellCalendarBloc>()
              .add(DateCellCalendarEvent.selectDay(selectedDay.toLocal().date)),
          onFormatChanged: (format) => context
              .read<DateCellCalendarBloc>()
              .add(DateCellCalendarEvent.setCalFormat(format)),
          onPageChanged: (focusedDay) => context
              .read<DateCellCalendarBloc>()
              .add(DateCellCalendarEvent.setFocusedDay(focusedDay)),
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
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: Padding(
              padding: GridSize.typeOptionContentInsets,
              child: Row(
                children: [
                  FlowySvg(
                    FlowySvgs.clock_alarm_s,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const HSpace(6),
                  FlowyText.medium(LocaleKeys.grid_field_includeTime.tr()),
                  const Spacer(),
                  Toggle(
                    value: includeTime,
                    onChanged: (value) => context
                        .read<DateCellCalendarBloc>()
                        .add(DateCellCalendarEvent.setIncludeTime(!value)),
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
  final String? timeStr;
  final PopoverMutex popoverMutex;

  const _TimeTextField({
    required this.timeStr,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

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
      listener: (context, state) => _textController.text = state.time ?? "",
      builder: (context, state) {
        return Column(
          children: [
            const VSpace(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: FlowyTextField(
                text: state.time ?? "",
                focusNode: _focusNode,
                controller: _textController,
                submitOnLeave: true,
                hintText: state.timeHintText,
                errorText: state.timeFormatError,
                onSubmitted: (timeStr) {
                  context
                      .read<DateCellCalendarBloc>()
                      .add(DateCellCalendarEvent.setTime(timeStr));
                },
              ),
            ),
          ],
        );
      },
    );
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
                margin: GridSize.typeOptionContentInsets,
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
          leftIcon: const FlowySvg(FlowySvgs.delete_s),
          margin: GridSize.typeOptionContentInsets,
        ),
      ),
    );
  }
}
