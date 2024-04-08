import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:intl/intl.dart';

const _maxLengthTwelveHour = 8;
const _maxLengthTwentyFourHour = 5;

class TimeTextField extends StatefulWidget {
  const TimeTextField({
    super.key,
    required this.isEndTime,
    required this.timeFormat,
    this.timeHintText,
    this.parseEndTimeError,
    this.parseTimeError,
    this.timeStr,
    this.endTimeStr,
    this.popoverMutex,
    this.onSubmitted,
  });

  final bool isEndTime;
  final TimeFormatPB timeFormat;
  final String? timeHintText;
  final String? parseEndTimeError;
  final String? parseTimeError;
  final String? timeStr;
  final String? endTimeStr;
  final PopoverMutex? popoverMutex;
  final Function(String timeStr)? onSubmitted;

  @override
  State<TimeTextField> createState() => _TimeTextFieldState();
}

class _TimeTextFieldState extends State<TimeTextField> {
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _textController = TextEditingController()
    ..text = widget.timeStr ?? "";
  String text = "";

  @override
  void initState() {
    super.initState();

    _textController.text =
        (widget.isEndTime ? widget.endTimeStr : widget.timeStr) ?? "";

    if (!widget.isEndTime && widget.timeStr != null) {
      text = widget.timeStr!;
    } else if (widget.endTimeStr != null) {
      text = widget.endTimeStr!;
    }

    if (widget.timeFormat == TimeFormatPB.TwelveHour) {
      final twentyFourHourFormat = DateFormat('HH:mm');
      final twelveHourFormat = DateFormat('hh:mm a');
      final date = twentyFourHourFormat.parse(text);
      text = twelveHourFormat.format(date);
    }

    _focusNode.addListener(_focusNodeListener);
    widget.popoverMutex?.listenOnPopoverChanged(_popoverListener);
  }

  @override
  void dispose() {
    widget.popoverMutex?.removePopoverListener(_popoverListener);
    _textController.dispose();
    _focusNode.removeListener(_focusNodeListener);
    _focusNode.dispose();
    super.dispose();
  }

  void _focusNodeListener() {
    if (_focusNode.hasFocus) {
      widget.popoverMutex?.close();
    }
  }

  void _popoverListener() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: FlowyTextField(
        text: text,
        keyboardType: TextInputType.datetime,
        focusNode: _focusNode,
        autoFocus: false,
        controller: _textController,
        submitOnLeave: true,
        hintText: widget.timeHintText,
        errorText:
            widget.isEndTime ? widget.parseEndTimeError : widget.parseTimeError,
        maxLength: widget.timeFormat == TimeFormatPB.TwelveHour
            ? _maxLengthTwelveHour
            : _maxLengthTwentyFourHour,
        showCounter: false,
        inputFormatters: [
          if (widget.timeFormat == TimeFormatPB.TwelveHour) ...[
            // Allow for AM/PM if time format is 12-hour
            FilteringTextInputFormatter.allow(RegExp('[0-9:aApPmM ]')),
          ] else ...[
            // Default allow for hh:mm format
            FilteringTextInputFormatter.allow(RegExp('[0-9:]')),
          ],
          TimeInputFormatter(widget.timeFormat),
        ],
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

class TimeInputFormatter extends TextInputFormatter {
  TimeInputFormatter(this.timeFormat);

  final TimeFormatPB timeFormat;
  static const int colonPosition = 2;
  static const int spacePosition = 5;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // If the user has typed enough for a time separator(:) and hasn't already typed
    if (newText.length == colonPosition + 1 &&
        oldText.length == colonPosition &&
        !newText.contains(":")) {
      return _formatText(newText, colonPosition, ':');
    }

    // If the user has typed enough for an AM/PM separator and hasn't already typed
    if (timeFormat == TimeFormatPB.TwelveHour &&
        newText.length == spacePosition + 1 &&
        oldText.length == spacePosition &&
        newText[newText.length - 1] != ' ') {
      return _formatText(newText, spacePosition, ' ');
    }

    if (timeFormat == TimeFormatPB.TwentyFourHour &&
        newValue.text.length == 5) {
      final prefix = newValue.text.substring(0, 3);
      final suffix = newValue.text.length > 5 ? newValue.text.substring(6) : '';

      final minutes = int.tryParse(newValue.text.substring(3, 5));
      if (minutes == null || minutes <= 0) {
        return newValue.copyWith(text: '${prefix}00$suffix'.toUpperCase());
      } else if (minutes > 59) {
        return newValue.copyWith(text: '${prefix}59$suffix'.toUpperCase());
      }
    }

    return newValue.copyWith(text: newText.toUpperCase());
  }

  TextEditingValue _formatText(String text, int index, String separator) {
    return TextEditingValue(
      text: '${text.substring(0, index)}$separator${text.substring(index)}',
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
  }
}
