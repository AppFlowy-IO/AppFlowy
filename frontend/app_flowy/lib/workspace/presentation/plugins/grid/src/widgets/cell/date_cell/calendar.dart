import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/grid/cell/date_cal_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/date.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:dartz/dartz.dart' show Option;

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
const kMargin = EdgeInsets.symmetric(horizontal: 6, vertical: 10);

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

    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: calendar,
        constraints: BoxConstraints.loose(const Size(320, 500)),
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

  @override
  bool asBarrier() => true;
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
          List<Widget> children = [];

          children.addAll([
            _buildCalendar(state, theme, context),
            const VSpace(10),
          ]);

          state.dateTypeOption.foldRight(null, (dateTypeOption, _) {
            children.addAll([
              const _TimeTextField(),
              const VSpace(10),
            ]);
          });

          children.addAll([
            Divider(height: 1, color: theme.shader5),
            const _IncludeTimeButton(),
          ]);

          children.add(const _DateTypeOptionButton());

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

  TableCalendar<dynamic> _buildCalendar(DateCalState state, AppTheme theme, BuildContext context) {
    return TableCalendar(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: state.focusedDay,
      rowHeight: 40,
      calendarFormat: state.format,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronMargin: EdgeInsets.zero,
        leftChevronPadding: EdgeInsets.zero,
        leftChevronIcon: svgWidget("home/arrow_left"),
        rightChevronPadding: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
        rightChevronIcon: svgWidget("home/arrow_right"),
      ),
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
        context.read<DateCalBloc>().add(DateCalEvent.setCalFormat(format));
      },
      onPageChanged: (focusedDay) {
        context.read<DateCalBloc>().add(DateCalEvent.setFocusedDay(focusedDay));
      },
    );
  }
}

class _IncludeTimeButton extends StatelessWidget {
  const _IncludeTimeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocSelector<DateCalBloc, DateCalState, bool>(
      selector: (state) => state.dateTypeOption.foldRight(false, (option, _) => option.includeTime),
      builder: (context, includeTime) {
        return SizedBox(
          height: 50,
          child: Padding(
            padding: kMargin,
            child: Row(
              children: [
                svgWidget("grid/clock", color: theme.iconColor),
                const HSpace(4),
                FlowyText.medium(LocaleKeys.grid_field_includeTime.tr(), fontSize: 14),
                const Spacer(),
                Switch(
                  value: includeTime,
                  onChanged: (newValue) => context.read<DateCalBloc>().add(DateCalEvent.setIncludeTime(newValue)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimeTextField extends StatelessWidget {
  const _TimeTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _DateTypeOptionButton extends StatelessWidget {
  const _DateTypeOptionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final title = LocaleKeys.grid_field_dateFormat.tr() + " &" + LocaleKeys.grid_field_timeFormat.tr();
    return BlocSelector<DateCalBloc, DateCalState, Option<DateTypeOption>>(
      selector: (state) => state.dateTypeOption,
      builder: (context, dateTypeOption) {
        return FlowyButton(
          text: FlowyText.medium(title, fontSize: 12),
          hoverColor: theme.hover,
          margin: kMargin,
          onTap: () {
            dateTypeOption.fold(() => null, (dateTypeOption) {
              final setting = _CalDateTimeSetting(dateTypeOption: dateTypeOption);
              setting.show(context);
            });
          },
          rightIcon: svgWidget("grid/more", color: theme.iconColor),
        );
      },
    );
  }
}

class _CalDateTimeSetting extends StatefulWidget {
  final DateTypeOption dateTypeOption;
  const _CalDateTimeSetting({required this.dateTypeOption, Key? key}) : super(key: key);

  @override
  State<_CalDateTimeSetting> createState() => _CalDateTimeSettingState();

  static String identifier() {
    return (_CalDateTimeSetting).toString();
  }

  void show(BuildContext context) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(140, 100)),
      ),
      identifier: _CalDateTimeSetting.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.rightWithCenterAligned,
    );
  }
}

class _CalDateTimeSettingState extends State<_CalDateTimeSetting> {
  String? overlayIdentifier;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      DateFormatButton(onTap: () {
        final list = DateFormatList(
          selectedFormat: widget.dateTypeOption.dateFormat,
          onSelected: (format) {
            context.read<DateCalBloc>().add(DateCalEvent.setDateFormat(format));
          },
        );
        _showOverlay(context, list);
      }),
      TimeFormatButton(
        timeFormat: widget.dateTypeOption.timeFormat,
        onTap: () {
          final list = TimeFormatList(
            selectedFormat: widget.dateTypeOption.timeFormat,
            onSelected: (format) {
              context.read<DateCalBloc>().add(DateCalEvent.setTimeFormat(format));
            },
          );
          _showOverlay(context, list);
        },
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

  void _showOverlay(BuildContext context, Widget child) {
    if (overlayIdentifier != null) {
      FlowyOverlay.of(context).remove(overlayIdentifier!);
    }

    overlayIdentifier = child.toString();
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: child,
        constraints: BoxConstraints.loose(const Size(460, 440)),
      ),
      identifier: overlayIdentifier!,
      anchorContext: context,
      anchorDirection: AnchorDirection.rightWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      anchorOffset: const Offset(-20, 0),
    );
  }
}
