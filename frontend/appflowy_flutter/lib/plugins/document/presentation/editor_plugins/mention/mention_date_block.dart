import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
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
  });

  final String date;
  final int index;
  final Node node;
  final bool isReminder;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      return const SizedBox.shrink();
    }

    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AppFlowyPopover(
          direction: PopoverDirection.bottomWithLeftAligned,
          constraints: BoxConstraints.loose(const Size(260, 300)),
          popupBuilder: (popoverContext) {
            return AppFlowyCalendar(
              format: CalendarFormat.month,
              firstDay: isReminder ? DateTime.now() : null,
              selectedDate: parsedDate,
              focusedDay: parsedDate,
              onDaySelected: (selectedDay, focusedDay) {
                final editorState = context.read<EditorState>();

                final transaction = editorState.transaction
                  ..formatText(node, index, 1, {
                    MentionBlockKeys.mention: {
                      MentionBlockKeys.type: isReminder
                          ? MentionType.reminder.name
                          : MentionType.date.name,
                      MentionBlockKeys.date: selectedDay.toIso8601String(),
                    },
                  });

                editorState.apply(transaction, withUpdateSelection: false);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowySvg(
                  name: isReminder ? 'grid/clock' : 'editor/date',
                  size: const Size.square(18.0),
                ),
                const HSpace(2),
                FlowyText(
                  DateFormat.yMd().format(parsedDate),
                  fontSize: fontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
