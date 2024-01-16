import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/date_cell/date_cell_editor_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/mobile_appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_header.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/non_secure.dart';

class MobileDateCellEditScreen extends StatefulWidget {
  static const routeName = '/edit_date_cell';

  // the type is DateCellController
  static const dateCellController = 'date_cell_controller';

  // bool value, default is true
  static const fullScreen = 'full_screen';

  const MobileDateCellEditScreen({
    super.key,
    required this.controller,
    this.showAsFullScreen = true,
  });

  final DateCellController controller;
  final bool showAsFullScreen;

  @override
  State<MobileDateCellEditScreen> createState() =>
      _MobileDateCellEditScreenState();
}

class _MobileDateCellEditScreenState extends State<MobileDateCellEditScreen> {
  ReminderOption _reminderOption = ReminderOption.none;

  @override
  Widget build(BuildContext context) =>
      widget.showAsFullScreen ? _buildFullScreen() : _buildNotFullScreen();

  Widget _buildFullScreen() {
    return Scaffold(
      appBar: AppBar(title: FlowyText.medium(LocaleKeys.titleBar_date.tr())),
      body: _buildDatePicker(),
    );
  }

  Widget _buildNotFullScreen() {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      snapSizes: const [0.4, 0.7, 1.0],
      builder: (_, controller) => Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListView(
          controller: controller,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: DragHandler()),
            ),
            const MobileDateHeader(),
            _buildDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() => MultiBlocProvider(
        providers: [
          BlocProvider<DateCellEditorBloc>(
            create: (_) => DateCellEditorBloc(cellController: widget.controller)
              ..add(const DateCellEditorEvent.initial()),
          ),
          BlocProvider<ReminderBloc>.value(value: getIt<ReminderBloc>()),
        ],
        child: BlocConsumer<DateCellEditorBloc, DateCellEditorState>(
          listenWhen: (prev, curr) =>
              curr.reminderId != null &&
              curr.reminderId!.isNotEmpty &&
              curr.dateTime != null,
          listener: (context, state) => _updateReminderScheduledAt(
            context.read<ReminderBloc>(),
            state.reminderId!,
            state.dateTime!,
          ),
          builder: (context, state) {
            final reminder = context
                .read<ReminderBloc>()
                .state
                .reminders
                .firstWhereOrNull((r) => r.id == state.reminderId);

            _reminderOption = reminder != null && state.dateTime != null
                ? ReminderOption.fromDateDifference(
                    state.dateTime!,
                    reminder.scheduledAt.toDateTime(),
                  )
                : ReminderOption.none;

            return MobileAppFlowyDatePicker(
              selectedDay: state.dateTime,
              dateStr: state.dateStr,
              endDateStr: state.endDateStr,
              timeStr: state.timeStr,
              endTimeStr: state.endTimeStr,
              startDay: state.startDay,
              endDay: state.endDay,
              enableRanges: true,
              isRange: state.isRange,
              includeTime: state.includeTime,
              use24hFormat: state.dateTypeOptionPB.timeFormat ==
                  TimeFormatPB.TwentyFourHour,
              selectedReminderOption: _reminderOption,
              onStartTimeChanged: (String? time) {
                if (time != null) {
                  context
                      .read<DateCellEditorBloc>()
                      .add(DateCellEditorEvent.setTime(time));
                }
              },
              onEndTimeChanged: (String? time) {
                if (time != null) {
                  context
                      .read<DateCellEditorBloc>()
                      .add(DateCellEditorEvent.setEndTime(time));
                }
              },
              onDaySelected: (selectedDay, focusedDay) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.selectDay(selectedDay)),
              onRangeSelected: (start, end, focused) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.selectDateRange(start, end)),
              onRangeChanged: (value) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.setIsRange(value)),
              onIncludeTimeChanged: (value) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.setIncludeTime(value)),
              onClearDate: () => context
                  .read<DateCellEditorBloc>()
                  .add(const DateCellEditorEvent.clearDate()),
              onReminderSelected: (option) => _updateReminderOption(
                option,
                cellBloc: context.read<DateCellEditorBloc>(),
                reminderBloc: context.read<ReminderBloc>(),
                rowId: widget.controller.rowId,
              ),
            );
          },
        ),
      );

  void _updateReminderScheduledAt(
    ReminderBloc bloc,
    String reminderId,
    DateTime scheduledAt,
  ) =>
      bloc.add(
        ReminderEvent.update(
          ReminderUpdate(
            id: reminderId,
            scheduledAt: scheduledAt.subtract(_reminderOption.time),
          ),
        ),
      );

  void _updateReminderOption(
    ReminderOption newOption, {
    required DateCellEditorBloc cellBloc,
    required ReminderBloc reminderBloc,
    required String rowId,
  }) {
    final dateOfEvent = cellBloc.state.dateTime;
    if (dateOfEvent == null) {
      return;
    }

    final reminderId = cellBloc.state.reminderId;
    if ((reminderId != null || (reminderId?.isEmpty ?? false)) &&
        newOption == ReminderOption.none) {
      // Remove reminder if there is a reminder
      final reminder = reminderBloc.state.reminders
          .firstWhereOrNull((r) => r.id == reminderId);

      if (reminder != null) {
        reminderBloc.add(ReminderEvent.remove(reminder: reminder));
      }

      // Remove reminderId in database
      return cellBloc.add(const DateCellEditorEvent.removeReminder());
    } else if ((reminderId == null || reminderId.isEmpty) &&
        newOption != ReminderOption.none) {
      // Add reminder
      final reminderId = nanoid();
      final scheduledAtDate = dateOfEvent.subtract(newOption.time);
      reminderBloc.add(
        ReminderEvent.add(
          reminder: ReminderPB(
            id: reminderId,
            objectId: widget.controller.viewId,
            title: LocaleKeys.reminderNotification_title.tr(),
            message: LocaleKeys.reminderNotification_message.tr(),
            scheduledAt: Int64(scheduledAtDate.millisecondsSinceEpoch ~/ 1000),
            isAck: dateOfEvent.isBefore(DateTime.now()),
            meta: {ReminderMetaKeys.rowId: rowId},
          ),
        ),
      );

      // Update reminderId in database
      return cellBloc.add(
        DateCellEditorEvent.setReminder(reminderId: reminderId),
      );
    }

    if (reminderId != null) {
      // Update reminder
      reminderBloc.add(
        ReminderEvent.update(
          ReminderUpdate(
            id: reminderId,
            scheduledAt: dateOfEvent.subtract(newOption.time),
          ),
        ),
      );
    }
  }
}
