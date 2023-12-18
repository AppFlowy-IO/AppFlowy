import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/date_time_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/user_time_format_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';

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
    this.includeTime = false,
    this.isRange = false,
    this.enableRanges = true,
    this.dateFormat = UserDateFormatPB.Friendly,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
    this.onDaySelected,
    this.onIncludeTimeChanged,
    this.onStartTimeChanged,
    this.onEndTimeChanged,
  }) : focusedDay = focusedDay ?? DateTime.now();

  final DateTime focusedDay;
  final PopoverMutex? popoverMutex;
  final DateTime? selectedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final String? timeStr;
  final bool includeTime;
  final bool isRange;
  final bool enableRanges;
  final UserDateFormatPB dateFormat;
  final UserTimeFormatPB timeFormat;

  final DaySelectedCallback? onDaySelected;
  final IncludeTimeChangedCallback? onIncludeTimeChanged;
  final TimeChangedCallback? onStartTimeChanged;
  final TimeChangedCallback? onEndTimeChanged;
}

abstract class DatePickerService {
  void show(Offset offset);
  void dismiss();
}

const double _datePickerWidth = 260;
const double _datePickerHeight = 355;
const double _includeTimeHeight = 40;
const double _ySpacing = 15;

class DatePickerMenu extends DatePickerService {
  DatePickerMenu({
    required this.context,
    required this.editorState,
  });

  final BuildContext context;
  final EditorState editorState;

  OverlayEntry? _menuEntry;

  @override
  void dismiss() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  @override
  void show(
    Offset offset, {
    DatePickerOptions? options,
  }) =>
      _show(offset, options: options);

  void _show(
    Offset offset, {
    DatePickerOptions? options,
  }) {
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
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: editorSize.height,
            width: editorSize.width,
            child: RawKeyboardListener(
              focusNode: FocusNode()..requestFocus(),
              onKey: (event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
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
        );
      },
    );

    Overlay.of(context).insert(_menuEntry!);
  }
}

class _AnimatedDatePicker extends StatefulWidget {
  const _AnimatedDatePicker({
    required this.offset,
    required this.showBelow,
    this.options,
  });

  final Offset offset;
  final bool showBelow;
  final DatePickerOptions? options;

  @override
  State<_AnimatedDatePicker> createState() => _AnimatedDatePickerState();
}

class _AnimatedDatePickerState extends State<_AnimatedDatePicker> {
  late bool _includeTime = widget.options?.includeTime ?? false;

  @override
  Widget build(BuildContext context) {
    double dy = widget.offset.dy;
    if (!widget.showBelow && _includeTime) {
      dy = dy - _includeTimeHeight;
    }

    dy = dy + (widget.showBelow ? _ySpacing : -_ySpacing);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: dy,
      left: widget.offset.dx,
      child: Container(
        decoration: FlowyDecoration.decoration(
          Theme.of(context).cardColor,
          Theme.of(context).colorScheme.shadow,
        ),
        constraints: BoxConstraints.loose(
          const Size(_datePickerWidth, 465),
        ),
        child: AppFlowyDatePicker(
          popoverMutex: widget.options?.popoverMutex,
          includeTime: _includeTime,
          enableRanges: widget.options?.enableRanges ?? false,
          isRange: widget.options?.isRange ?? false,
          onIsRangeChanged: (_) {},
          timeStr: widget.options?.timeStr,
          dateFormat:
              widget.options?.dateFormat.simplified ?? DateFormatPB.Friendly,
          timeFormat: widget.options?.timeFormat.simplified ??
              TimeFormatPB.TwentyFourHour,
          selectedDay: widget.options?.selectedDay,
          onIncludeTimeChanged: (includeTime) {
            widget.options?.onIncludeTimeChanged?.call(!includeTime);
            setState(() => _includeTime = !includeTime);
          },
          onStartTimeSubmitted: widget.options?.onStartTimeChanged,
          onDaySelected: widget.options?.onDaySelected,
          focusedDay: widget.options?.focusedDay ?? DateTime.now(),
          firstDay: widget.options?.firstDay,
          lastDay: widget.options?.lastDay,
        ),
      ),
    );
  }
}
