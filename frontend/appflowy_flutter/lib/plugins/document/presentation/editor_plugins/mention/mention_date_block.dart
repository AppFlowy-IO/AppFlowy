import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

class MentionDateBlock extends StatelessWidget {
  const MentionDateBlock({
    super.key,
    required this.date,
    required this.index,
    required this.node,
    this.isReminder = false,
    this.reminderId,
    this.includeTime = false,
  });

  final String date;
  final int index;
  final Node node;
  final bool isReminder;
  final String? reminderId;
  final bool includeTime;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      return const SizedBox.shrink();
    }

    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AppearanceSettingsCubit>.value(
          value: context.read<AppearanceSettingsCubit>(),
        ),
        BlocProvider<ReminderBloc>.value(
          value: getIt<ReminderBloc>(),
        ),
      ],
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        buildWhen: (previous, current) =>
            previous.dateFormat != current.dateFormat ||
            previous.timeFormat != current.timeFormat,
        builder: (context, appearance) {
          return BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              final reminder =
                  state.reminders.firstWhereOrNull((r) => r.id == reminderId);
              final noReminder = reminder == null && isReminder;

              final formattedDate = appearance.dateFormat.formatDate(
                parsedDate,
                includeTime,
                appearance.timeFormat,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AppFlowyPopover(
                    direction: PopoverDirection.bottomWithLeftAligned,
                    constraints: BoxConstraints.loose(const Size(260, 420)),
                    popupBuilder: (popoverContext) {
                      return AppFlowyCalendar(
                        format: CalendarFormat.month,
                        firstDay: isReminder
                            ? noReminder
                                ? parsedDate
                                : DateTime.now()
                            : null,
                        lastDay: noReminder ? parsedDate : null,
                        selectedDate: parsedDate,
                        focusedDay: parsedDate,
                        includeTime: includeTime,
                        timeFormat: appearance.timeFormat,
                        // We can already remove time from the date/reminder
                        //  block when toggled off.
                        onIncludeDisabled: () {
                          final editorState = context.read<EditorState>();
                          final transaction = editorState.transaction
                            ..formatText(node, index, 1, {
                              MentionBlockKeys.mention: {
                                MentionBlockKeys.type: isReminder
                                    ? MentionType.reminder.name
                                    : MentionType.date.name,
                                MentionBlockKeys.date:
                                    parsedDate.withoutTime.toIso8601String(),
                                MentionBlockKeys.uid: reminderId,
                                MentionBlockKeys.includeTime: false,
                              },
                            });

                          editorState.apply(
                            transaction,
                            withUpdateSelection: false,
                          );

                          // Length of rendered block changes, this synchronizes
                          //  the cursor with the new block render
                          editorState.updateSelectionWithReason(
                            editorState.selection,
                            reason: SelectionUpdateReason.transaction,
                          );

                          context.read<ReminderBloc>().add(
                                ReminderEvent.update(
                                  reminderId: reminderId!,
                                  date: parsedDate.withoutTime,
                                ),
                              );
                        },
                        onDaySelected: (selectedDay, focusedDay, includeTime) {
                          final editorState = context.read<EditorState>();

                          final transaction = editorState.transaction
                            ..formatText(node, index, 1, {
                              MentionBlockKeys.mention: {
                                MentionBlockKeys.type: isReminder
                                    ? MentionType.reminder.name
                                    : MentionType.date.name,
                                MentionBlockKeys.date:
                                    selectedDay.toIso8601String(),
                                MentionBlockKeys.uid: reminderId,
                                MentionBlockKeys.includeTime: includeTime,
                              },
                            });

                          editorState.apply(
                            transaction,
                            withUpdateSelection: false,
                          );

                          // Length of rendered block can have
                          //  changed, this synchronizes the cursor
                          //  with the new block render
                          editorState.updateSelectionWithReason(
                            editorState.selection,
                            reason: SelectionUpdateReason.transaction,
                          );

                          if (isReminder &&
                              date != selectedDay.toIso8601String()) {
                            context.read<ReminderBloc>().add(
                                  ReminderEvent.update(
                                    reminderId: reminderId!,
                                    date: selectedDay,
                                  ),
                                );
                          }
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlowySvg(
                            isReminder
                                ? FlowySvgs.clock_alarm_s
                                : FlowySvgs.date_s,
                            size: const Size.square(18.0),
                            color: noReminder
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                          const HSpace(2),
                          FlowyText(
                            formattedDate,
                            fontSize: fontSize,
                            color: noReminder
                                ? Theme.of(context).colorScheme.error
                                : null,
                            decoration: reminder?.isAck ?? false
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
