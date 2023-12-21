import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker_dialog.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MentionDateBlock extends StatefulWidget {
  const MentionDateBlock({
    super.key,
    required this.editorContext,
    required this.date,
    required this.index,
    required this.node,
    this.isReminder = false,
    this.reminderId,
    this.includeTime = false,
  });

  final BuildContext editorContext;
  final String date;
  final int index;
  final Node node;

  final bool isReminder;

  /// If [isReminder] is true, then this must not be
  /// null or empty
  final String? reminderId;

  final bool includeTime;

  @override
  State<MentionDateBlock> createState() => _MentionDateBlockState();
}

class _MentionDateBlockState extends State<MentionDateBlock> {
  late bool includeTime = widget.includeTime;
  final PopoverMutex mutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    final editorState = context.read<EditorState>();

    DateTime? parsedDate = DateTime.tryParse(widget.date);
    if (parsedDate == null) {
      return const SizedBox.shrink();
    }

    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>.value(value: context.read<ReminderBloc>()),
        BlocProvider<AppearanceSettingsCubit>.value(
          value: context.read<AppearanceSettingsCubit>(),
        ),
      ],
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        buildWhen: (previous, current) =>
            previous.dateFormat != current.dateFormat ||
            previous.timeFormat != current.timeFormat,
        builder: (context, appearance) =>
            BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) {
            final reminder = state.reminders
                .firstWhereOrNull((r) => r.id == widget.reminderId);
            final noReminder = reminder == null && widget.isReminder;

            final formattedDate = appearance.dateFormat
                .formatDate(parsedDate!, includeTime, appearance.timeFormat);

            final timeStr = parsedDate != null
                ? _timeFromDate(parsedDate!, appearance.timeFormat)
                : null;

            final options = DatePickerOptions(
              focusedDay: parsedDate,
              popoverMutex: mutex,
              selectedDay: parsedDate,
              firstDay: widget.isReminder
                  ? noReminder
                      ? parsedDate
                      : DateTime.now()
                  : null,
              lastDay: noReminder ? parsedDate : null,
              timeStr: timeStr,
              includeTime: includeTime,
              enableRanges: false,
              dateFormat: appearance.dateFormat,
              timeFormat: appearance.timeFormat,
              onIncludeTimeChanged: (includeTime) {
                this.includeTime = includeTime;
                _updateBlock(parsedDate!.withoutTime, includeTime);

                // We can remove time from the date/reminder
                // block when toggled off.
                if (widget.isReminder) {
                  _updateScheduledAt(
                    reminderId: widget.reminderId!,
                    selectedDay:
                        includeTime ? parsedDate! : parsedDate!.withoutTime,
                    includeTime: includeTime,
                  );
                }
              },
              onStartTimeChanged: (time) {
                final parsed = _parseTime(time, appearance.timeFormat);
                parsedDate = parsedDate!.withoutTime
                    .add(Duration(hours: parsed.hour, minutes: parsed.minute));

                _updateBlock(parsedDate!, includeTime);

                if (widget.isReminder &&
                    widget.date != parsedDate!.toIso8601String()) {
                  _updateScheduledAt(
                    reminderId: widget.reminderId!,
                    selectedDay: parsedDate!,
                  );
                }
              },
              onDaySelected: (selectedDay, focusedDay) {
                parsedDate = selectedDay;
                _updateBlock(selectedDay, includeTime);

                if (widget.isReminder &&
                    widget.date != selectedDay.toIso8601String()) {
                  _updateScheduledAt(
                    reminderId: widget.reminderId!,
                    selectedDay: selectedDay,
                  );
                }
              },
            );

            return GestureDetector(
              onTapDown: editorState.editable
                  ? (details) => DatePickerMenu(
                        context: context,
                        editorState: context.read<EditorState>(),
                      ).show(details.globalPosition, options: options)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        widget.isReminder
                            ? FlowySvgs.clock_alarm_s
                            : FlowySvgs.date_s,
                        size: const Size.square(18.0),
                        color: widget.isReminder && reminder?.isAck == true
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const HSpace(2),
                      FlowyText(
                        formattedDate,
                        fontSize: fontSize,
                        color: widget.isReminder && reminder?.isAck == true
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DateTime _parseTime(String timeStr, UserTimeFormatPB timeFormat) {
    final twelveHourFormat = DateFormat('HH:mm a');
    final twentyFourHourFormat = DateFormat('HH:mm');

    if (timeFormat == TimeFormatPB.TwelveHour) {
      return twelveHourFormat.parse(timeStr);
    }

    return twentyFourHourFormat.parse(timeStr);
  }

  String _timeFromDate(DateTime date, UserTimeFormatPB timeFormat) {
    final twelveHourFormat = DateFormat('HH:mm a');
    final twentyFourHourFormat = DateFormat('HH:mm');

    if (timeFormat == TimeFormatPB.TwelveHour) {
      return twelveHourFormat.format(date);
    }

    return twentyFourHourFormat.format(date);
  }

  void _updateBlock(
    DateTime date, [
    bool includeTime = false,
  ]) {
    final editorState = widget.editorContext.read<EditorState>();
    final transaction = editorState.transaction
      ..formatText(widget.node, widget.index, 1, {
        MentionBlockKeys.mention: {
          MentionBlockKeys.type: widget.isReminder
              ? MentionType.reminder.name
              : MentionType.date.name,
          MentionBlockKeys.date: date.toIso8601String(),
          MentionBlockKeys.uid: widget.reminderId,
          MentionBlockKeys.includeTime: includeTime,
        },
      });

    editorState.apply(transaction, withUpdateSelection: false);

    // Length of rendered block changes, this synchronizes
    //  the cursor with the new block render
    editorState.updateSelectionWithReason(
      editorState.selection,
      reason: SelectionUpdateReason.transaction,
    );
  }

  void _updateScheduledAt({
    required String reminderId,
    required DateTime selectedDay,
    bool? includeTime,
  }) {
    widget.editorContext.read<ReminderBloc>().add(
          ReminderEvent.update(
            ReminderUpdate(
              id: reminderId,
              scheduledAt: selectedDay,
              includeTime: includeTime,
            ),
          ),
        );
  }
}
