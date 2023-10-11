import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_calendar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provides arguemnts for [AppFlowyCalender] when showing
/// a [DatePickerMenu]
///
class DatePickerOptions {
  DatePickerOptions({
    DateTime? focusedDay,
    this.selectedDay,
    this.firstDay,
    this.lastDay,
    this.includeTime = false,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
    this.onDaySelected,
    this.onIncludeTimeChanged,
    this.onFormatChanged,
    this.onPageChanged,
    this.onTimeChanged,
  }) : focusedDay = focusedDay ?? DateTime.now();

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final bool includeTime;
  final UserTimeFormatPB timeFormat;

  final DaySelectedCallback? onDaySelected;
  final IncludeTimeChangedCallback? onIncludeTimeChanged;
  final FormatChangedCallback? onFormatChanged;
  final PageChangedCallback? onPageChanged;
  final TimeChangedCallback? onTimeChanged;
}

abstract class DatePickerService {
  void show(Offset offset);
  void dismiss();
}

const double _datePickerWidth = 260;
const double _datePickerHeight = 325;
const double _includeTimeHeight = 60;
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

    // Use MediaQuery, since Stack takes up all window space
    // and not just the space of the current Editor
    final windowSize = MediaQuery.of(context).size;

    double offsetX = offset.dx;
    double offsetY = offset.dy;

    final showRight = (offset.dx + _datePickerWidth) < windowSize.width;
    if (!showRight) {
      offsetX = offset.dx - _datePickerWidth;
    }

    final showBelow = (offset.dy + _datePickerHeight) < windowSize.height;
    if (!showBelow) {
      offsetY = offset.dy - _datePickerHeight;
    }

    _menuEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: windowSize.height,
            width: windowSize.width,
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
        child: AppFlowyCalendar(
          focusedDay: widget.options?.focusedDay ?? DateTime.now(),
          selectedDate: widget.options?.selectedDay,
          firstDay: widget.options?.firstDay,
          lastDay: widget.options?.lastDay,
          includeTime: widget.options?.includeTime ?? false,
          timeFormat:
              widget.options?.timeFormat ?? UserTimeFormatPB.TwentyFourHour,
          onDaySelected: widget.options?.onDaySelected,
          onFormatChanged: widget.options?.onFormatChanged,
          onPageChanged: widget.options?.onPageChanged,
          onIncludeTimeChanged: (includeTime) {
            widget.options?.onIncludeTimeChanged?.call(includeTime);
            setState(() => _includeTime = includeTime);
          },
          onTimeChanged: widget.options?.onTimeChanged,
        ),
      ),
    );
  }
}
