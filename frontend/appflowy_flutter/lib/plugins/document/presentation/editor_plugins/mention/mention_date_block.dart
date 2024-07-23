import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/mobile_appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/user_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker_dialog.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_header.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/non_secure.dart';

class MentionDateBlock extends StatefulWidget {
  const MentionDateBlock({
    super.key,
    required this.editorState,
    required this.date,
    required this.index,
    required this.node,
    this.reminderId,
    this.reminderOption,
    this.includeTime = false,
  });

  final EditorState editorState;
  final String date;
  final int index;
  final Node node;

  /// If [isReminder] is true, then this must not be
  /// null or empty
  final String? reminderId;

  final ReminderOption? reminderOption;

  final bool includeTime;

  @override
  State<MentionDateBlock> createState() => _MentionDateBlockState();
}

class _MentionDateBlockState extends State<MentionDateBlock> {
  final PopoverMutex mutex = PopoverMutex();

  late bool _includeTime = widget.includeTime;
  late DateTime? parsedDate = DateTime.tryParse(widget.date);

  @override
  void dispose() {
    mutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            final formattedDate = appearance.dateFormat
                .formatDate(parsedDate!, _includeTime, appearance.timeFormat);

            final timeStr = parsedDate != null
                ? _timeFromDate(parsedDate!, appearance.timeFormat)
                : null;

            final options = DatePickerOptions(
              focusedDay: parsedDate,
              popoverMutex: mutex,
              selectedDay: parsedDate,
              timeStr: timeStr,
              includeTime: _includeTime,
              dateFormat: appearance.dateFormat,
              timeFormat: appearance.timeFormat,
              selectedReminderOption: widget.reminderOption,
              onIncludeTimeChanged: (includeTime) {
                _includeTime = includeTime;

                if (![null, ReminderOption.none]
                    .contains(widget.reminderOption)) {
                  _updateReminder(
                    widget.reminderOption!,
                    reminder,
                    includeTime,
                  );
                } else {
                  _updateBlock(
                    parsedDate!.withoutTime,
                    includeTime: includeTime,
                  );
                }
              },
              onStartTimeChanged: (time) {
                final parsed = _parseTime(time, appearance.timeFormat);
                parsedDate = parsedDate!.withoutTime
                    .add(Duration(hours: parsed.hour, minutes: parsed.minute));

                if (![null, ReminderOption.none]
                    .contains(widget.reminderOption)) {
                  _updateReminder(
                    widget.reminderOption!,
                    reminder,
                    _includeTime,
                  );
                } else {
                  _updateBlock(parsedDate!, includeTime: _includeTime);
                }
              },
              onDaySelected: (selectedDay, focusedDay) {
                parsedDate = selectedDay;

                if (![null, ReminderOption.none]
                    .contains(widget.reminderOption)) {
                  _updateReminder(
                    widget.reminderOption!,
                    reminder,
                    _includeTime,
                  );
                } else {
                  _updateBlock(selectedDay, includeTime: _includeTime);
                }
              },
              onReminderSelected: (reminderOption) =>
                  _updateReminder(reminderOption, reminder),
            );

            return GestureDetector(
              onTapDown: (details) {
                if (widget.editorState.editable) {
                  if (PlatformExtension.isMobile) {
                    showMobileBottomSheet(
                      context,
                      builder: (_) => DraggableScrollableSheet(
                        expand: false,
                        snap: true,
                        initialChildSize: 0.7,
                        minChildSize: 0.4,
                        snapSizes: const [0.4, 0.7, 1.0],
                        builder: (_, controller) => Material(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: ListView(
                            controller: controller,
                            children: [
                              ColoredBox(
                                color: Theme.of(context).colorScheme.surface,
                                child: const Center(child: DragHandle()),
                              ),
                              const MobileDateHeader(),
                              MobileAppFlowyDatePicker(
                                selectedDay: parsedDate,
                                timeStr: timeStr,
                                dateStr: parsedDate != null
                                    ? options.dateFormat
                                        .formatDate(parsedDate!, _includeTime)
                                    : null,
                                includeTime: options.includeTime,
                                use24hFormat: options.timeFormat ==
                                    UserTimeFormatPB.TwentyFourHour,
                                rebuildOnDaySelected: true,
                                rebuildOnTimeChanged: true,
                                timeFormat: options.timeFormat.simplified,
                                selectedReminderOption: widget.reminderOption,
                                onDaySelected: options.onDaySelected,
                                onStartTimeChanged: (time) => options
                                    .onStartTimeChanged
                                    ?.call(time ?? ""),
                                onIncludeTimeChanged:
                                    options.onIncludeTimeChanged,
                                liveDateFormatter: (selected) =>
                                    appearance.dateFormat.formatDate(
                                  selected,
                                  false,
                                  appearance.timeFormat,
                                ),
                                onReminderSelected: (option) =>
                                    _updateReminder(option, reminder),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    DatePickerMenu(
                      context: context,
                      editorState: widget.editorState,
                    ).show(details.globalPosition, options: options);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        widget.reminderId != null
                            ? FlowySvgs.clock_alarm_s
                            : FlowySvgs.date_s,
                        size: const Size.square(18.0),
                        color: reminder?.isAck == true
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const HSpace(2),
                      FlowyText(
                        formattedDate,
                        fontSize: fontSize,
                        color: reminder?.isAck == true
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
    final twelveHourFormat = DateFormat('hh:mm a');
    final twentyFourHourFormat = DateFormat('HH:mm');

    try {
      if (timeFormat == UserTimeFormatPB.TwelveHour) {
        return twelveHourFormat.parseStrict(timeStr);
      }

      return twentyFourHourFormat.parseStrict(timeStr);
    } on FormatException {
      Log.error("failed to parse time string ($timeStr)");
      return DateTime.now();
    }
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
    DateTime date, {
    bool includeTime = false,
    String? reminderId,
    ReminderOption? reminderOption,
  }) {
    final rId = reminderId ??
        (reminderOption == ReminderOption.none ? null : widget.reminderId);

    final transaction = widget.editorState.transaction
      ..formatText(widget.node, widget.index, 1, {
        MentionBlockKeys.mention: {
          MentionBlockKeys.type: MentionType.date.name,
          MentionBlockKeys.date: date.toIso8601String(),
          MentionBlockKeys.reminderId: rId,
          MentionBlockKeys.includeTime: includeTime,
          MentionBlockKeys.reminderOption:
              reminderOption?.name ?? widget.reminderOption?.name,
        },
      });

    widget.editorState.apply(transaction, withUpdateSelection: false);

    // Length of rendered block changes, this synchronizes
    //  the cursor with the new block render
    widget.editorState.updateSelectionWithReason(
      widget.editorState.selection,
    );
  }

  void _updateReminder(
    ReminderOption reminderOption,
    ReminderPB? reminder, [
    bool includeTime = false,
  ]) {
    final rootContext = widget.editorState.document.root.context;
    if (parsedDate == null || rootContext == null) {
      return;
    }

    if (widget.reminderId != null) {
      _updateBlock(
        parsedDate!,
        includeTime: includeTime,
        reminderOption: reminderOption,
      );

      if (ReminderOption.none == reminderOption && reminder != null) {
        // Delete existing reminder
        return rootContext
            .read<ReminderBloc>()
            .add(ReminderEvent.remove(reminderId: reminder.id));
      }

      // Update existing reminder
      return rootContext.read<ReminderBloc>().add(
            ReminderEvent.update(
              ReminderUpdate(
                id: widget.reminderId!,
                scheduledAt: reminderOption.fromDate(parsedDate!),
              ),
            ),
          );
    }

    final reminderId = nanoid();
    _updateBlock(
      parsedDate!,
      includeTime: includeTime,
      reminderId: reminderId,
      reminderOption: reminderOption,
    );

    // Add new reminder
    final viewId = rootContext.read<DocumentBloc>().documentId;
    return rootContext.read<ReminderBloc>().add(
          ReminderEvent.add(
            reminder: ReminderPB(
              id: reminderId,
              objectId: viewId,
              title: LocaleKeys.reminderNotification_title.tr(),
              message: LocaleKeys.reminderNotification_message.tr(),
              meta: {
                ReminderMetaKeys.includeTime: false.toString(),
                ReminderMetaKeys.blockId: widget.node.id,
                ReminderMetaKeys.createdAt:
                    DateTime.now().millisecondsSinceEpoch.toString(),
              },
              scheduledAt: Int64(parsedDate!.millisecondsSinceEpoch ~/ 1000),
              isAck: parsedDate!.isBefore(DateTime.now()),
            ),
          ),
        );
  }
}
