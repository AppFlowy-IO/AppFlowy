import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker_dialog.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MentionDateBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    DateTime? parsedDate = DateTime.tryParse(date);
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
            final reminder =
                state.reminders.firstWhereOrNull((r) => r.id == reminderId);
            final noReminder = reminder == null && isReminder;

            final formattedDate = appearance.dateFormat
                .formatDate(parsedDate!, includeTime, appearance.timeFormat);

            final options = DatePickerOptions(
              selectedDay: parsedDate,
              focusedDay: parsedDate,
              firstDay: isReminder
                  ? noReminder
                      ? parsedDate
                      : DateTime.now()
                  : null,
              lastDay: noReminder ? parsedDate : null,
              includeTime: includeTime,
              timeFormat: appearance.timeFormat,
              onIncludeTimeChanged: (includeTime) {
                _updateBlock(parsedDate!.withoutTime, includeTime);

                // We can remove time from the date/reminder
                // block when toggled off.
                if (isReminder) {
                  _updateScheduledAt(
                    reminderId: reminderId!,
                    selectedDay:
                        includeTime ? parsedDate! : parsedDate!.withoutTime,
                    includeTime: includeTime,
                  );
                }
              },
              onDaySelected: (selectedDay, focusedDay, includeTime) {
                parsedDate = selectedDay;

                _updateBlock(selectedDay, includeTime);

                if (isReminder && date != selectedDay.toIso8601String()) {
                  _updateScheduledAt(
                    reminderId: reminderId!,
                    selectedDay: selectedDay,
                    includeTime: includeTime,
                  );
                }
              },
            );

            return GestureDetector(
              onTapDown: (details) => DatePickerMenu(
                context: context,
                editorState: context.read<EditorState>(),
              ).show(details.globalPosition, options: options),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        isReminder ? FlowySvgs.clock_alarm_s : FlowySvgs.date_s,
                        size: const Size.square(18.0),
                        color: isReminder && reminder?.isAck == true
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const HSpace(2),
                      FlowyText(
                        formattedDate,
                        fontSize: fontSize,
                        color: isReminder && reminder?.isAck == true
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

  void _updateBlock(
    DateTime date, [
    bool includeTime = false,
  ]) {
    final editorState = editorContext.read<EditorState>();
    final transaction = editorState.transaction
      ..formatText(node, index, 1, {
        MentionBlockKeys.mention: {
          MentionBlockKeys.type:
              isReminder ? MentionType.reminder.name : MentionType.date.name,
          MentionBlockKeys.date: date.toIso8601String(),
          MentionBlockKeys.uid: reminderId,
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
    editorContext.read<ReminderBloc>().add(
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
