import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/date_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/user_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provides arguemnts for [AppFlowyDatePicker] when showing
/// a [DatePickerMenu]
///
class DatePickerOptions {
  DatePickerOptions({
    DateTime? focusedDay,
    this.popoverMutex,
    this.selectedDay,
    this.firstDay,
    this.lastDay,
    this.timeStr,
    this.endTimeStr,
    this.includeTime = false,
    this.isRange = false,
    this.enableRanges = true,
    this.dateFormat = UserDateFormatPB.Friendly,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
    this.selectedReminderOption,
    this.onDaySelected,
    required this.onIncludeTimeChanged,
    this.onStartTimeChanged,
    this.onEndTimeChanged,
    this.onRangeSelected,
    this.onIsRangeChanged,
    this.onReminderSelected,
  }) : focusedDay = focusedDay ?? DateTime.now();

  final DateTime focusedDay;
  final PopoverMutex? popoverMutex;
  final DateTime? selectedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final String? timeStr;
  final String? endTimeStr;
  final bool includeTime;
  final bool isRange;
  final bool enableRanges;
  final UserDateFormatPB dateFormat;
  final UserTimeFormatPB timeFormat;
  final ReminderOption? selectedReminderOption;

  final DaySelectedCallback? onDaySelected;
  final IncludeTimeChangedCallback onIncludeTimeChanged;
  final TimeChangedCallback? onStartTimeChanged;
  final TimeChangedCallback? onEndTimeChanged;
  final RangeSelectedCallback? onRangeSelected;
  final Function(bool)? onIsRangeChanged;
  final OnReminderSelected? onReminderSelected;
}

abstract class DatePickerService {
  void show(Offset offset, {required DatePickerOptions options});
  void dismiss();
}

const double _datePickerWidth = 260;
const double _datePickerHeight = 370;
const double _includeTimeHeight = 32;
const double _ySpacing = 15;

class DatePickerMenu extends DatePickerService {
  DatePickerMenu({required this.context, required this.editorState});

  final BuildContext context;
  final EditorState editorState;

  OverlayEntry? _menuEntry;

  @override
  void dismiss() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  void show(Offset offset, {required DatePickerOptions options}) =>
      _show(offset, options: options);

  void _show(Offset offset, {required DatePickerOptions options}) {
    dismiss();

    final editorSize = editorState.renderBox!.size;

    double offsetX = offset.dx;
    double offsetY = offset.dy;

    final showRight = (offset.dx + _datePickerWidth) < editorSize.width;
    if (!showRight) {
      offsetX = offset.dx - _datePickerWidth;
    }

    final showBelow = (offset.dy + _datePickerHeight) < editorSize.height;
    if (!showBelow) {
      if ((offset.dy - _datePickerHeight) < 0) {
        // Show dialog in the middle
        offsetY = offset.dy - (_datePickerHeight / 3);
      } else {
        // Show above
        offsetY = offset.dy - _datePickerHeight;
      }
    }

    _menuEntry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: editorSize.height,
          width: editorSize.width,
          child: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                dismiss();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: Stack(
                children: [
                  _AnimatedDatePicker(
                    offset: Offset(offsetX, offsetY),
                    showBelow: showBelow,
                    options: options,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);
  }
}

class _AnimatedDatePicker extends StatefulWidget {
  const _AnimatedDatePicker({
    required this.offset,
    required this.showBelow,
    required this.options,
  });

  final Offset offset;
  final bool showBelow;
  final DatePickerOptions options;

  @override
  State<_AnimatedDatePicker> createState() => _AnimatedDatePickerState();
}

class _AnimatedDatePickerState extends State<_AnimatedDatePicker> {
  late bool _includeTime = widget.options.includeTime;

  @override
  Widget build(BuildContext context) {
    double dy = widget.offset.dy;
    if (!widget.showBelow && _includeTime) {
      dy -= _includeTimeHeight;
    }

    dy += (widget.showBelow ? _ySpacing : -_ySpacing);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: dy,
      left: widget.offset.dx,
      child: Container(
        decoration: FlowyDecoration.decoration(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.shadow,
        ),
        constraints: BoxConstraints.loose(const Size(_datePickerWidth, 465)),
        child: AppFlowyDatePicker(
          includeTime: _includeTime,
          onIncludeTimeChanged: (includeTime) {
            widget.options.onIncludeTimeChanged.call(!includeTime);
            setState(() => _includeTime = !includeTime);
          },
          enableRanges: widget.options.enableRanges,
          isRange: widget.options.isRange,
          onIsRangeChanged: widget.options.onIsRangeChanged,
          dateFormat: widget.options.dateFormat.simplified,
          timeFormat: widget.options.timeFormat.simplified,
          selectedDay: widget.options.selectedDay,
          focusedDay: widget.options.focusedDay,
          firstDay: widget.options.firstDay,
          lastDay: widget.options.lastDay,
          timeStr: widget.options.timeStr,
          endTimeStr: widget.options.endTimeStr,
          popoverMutex: widget.options.popoverMutex,
          selectedReminderOption:
              widget.options.selectedReminderOption ?? ReminderOption.none,
          onStartTimeSubmitted: widget.options.onStartTimeChanged,
          onDaySelected: widget.options.onDaySelected,
          onRangeSelected: widget.options.onRangeSelected,
          onReminderSelected: widget.options.onReminderSelected,
        ),
      ),
    );
  }
}
