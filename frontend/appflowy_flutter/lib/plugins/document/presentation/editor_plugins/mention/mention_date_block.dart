import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/util/theme_extension.dart';
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
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/non_secure.dart';
import 'package:universal_platform/universal_platform.dart';

class MentionDateBlock extends StatefulWidget {
  const MentionDateBlock({
    super.key,
    required this.editorState,
    required this.date,
    required this.index,
    required this.node,
    this.textStyle,
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

  final TextStyle? textStyle;

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
                    parsedDate!,
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

            Color? color;
            if (reminder != null) {
              if (reminder.type == ReminderType.today) {
                color = Theme.of(context).isLightMode
                    ? const Color(0xFFFE0299)
                    : Theme.of(context).colorScheme.error;
              }
            }
            final textStyle = widget.textStyle?.copyWith(
              color: color,
              leadingDistribution: TextLeadingDistribution.even,
            );

            // when font size equals 14, the icon size is 16.0.
            // scale the icon size based on the font size.
            final iconSize = (widget.textStyle?.fontSize ?? 14.0) / 14.0 * 16.0;

            return GestureDetector(
              onTapDown: (details) {
                _showDatePicker(
                  context: context,
                  offset: details.globalPosition,
                  reminder: reminder,
                  timeStr: timeStr,
                  options: options,
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@$formattedDate',
                      style: textStyle,
                      strutStyle: textStyle != null
                          ? StrutStyle.fromTextStyle(textStyle)
                          : null,
                    ),
                    const HSpace(4),
                    FlowySvg(
                      widget.reminderId != null
                          ? FlowySvgs.reminder_clock_s
                          : FlowySvgs.date_s,
                      size: Size.square(iconSize),
                      color: textStyle?.color,
                    ),
                  ],
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
                date: parsedDate!,
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

  void _showDatePicker({
    required BuildContext context,
    required DatePickerOptions options,
    required Offset offset,
    String? timeStr,
    ReminderPB? reminder,
  }) {
    if (!widget.editorState.editable) {
      return;
    }
    if (UniversalPlatform.isMobile) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      showMobileBottomSheet(
        context,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          snap: true,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          snapSizes: const [0.4, 0.7, 1.0],
          builder: (_, controller) => _DatePickerBottomSheet(
            controller: controller,
            parsedDate: parsedDate,
            timeStr: timeStr,
            options: options,
            includeTime: _includeTime,
            reminderOption: widget.reminderOption,
            onReminderSelected: (option) => _updateReminder(
              option,
              reminder,
            ),
          ),
        ),
      );
    } else {
      DatePickerMenu(
        context: context,
        editorState: widget.editorState,
      ).show(offset, options: options);
    }
  }
}

class _DatePickerBottomSheet extends StatelessWidget {
  const _DatePickerBottomSheet({
    required this.controller,
    required this.parsedDate,
    required this.timeStr,
    required this.options,
    required this.includeTime,
    this.reminderOption,
    required this.onReminderSelected,
  });

  final ScrollController controller;
  final DateTime? parsedDate;
  final String? timeStr;
  final DatePickerOptions options;
  final bool includeTime;
  final ReminderOption? reminderOption;
  final void Function(ReminderOption) onReminderSelected;

  @override
  Widget build(BuildContext context) {
    final appearance = context.read<AppearanceSettingsCubit>().state;

    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
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
                ? options.dateFormat.formatDate(parsedDate!, includeTime)
                : null,
            includeTime: options.includeTime,
            use24hFormat: options.timeFormat == UserTimeFormatPB.TwentyFourHour,
            rebuildOnDaySelected: true,
            rebuildOnTimeChanged: true,
            timeFormat: options.timeFormat.simplified,
            selectedReminderOption: reminderOption,
            onDaySelected: options.onDaySelected,
            onStartTimeChanged: (time) =>
                options.onStartTimeChanged?.call(time ?? ""),
            onIncludeTimeChanged: options.onIncludeTimeChanged,
            liveDateFormatter: (selected) => appearance.dateFormat.formatDate(
              selected,
              false,
              appearance.timeFormat,
            ),
            onReminderSelected: onReminderSelected,
          ),
        ],
      ),
    );
  }
}
