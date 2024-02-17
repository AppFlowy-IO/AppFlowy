import 'package:flutter/material.dart';

import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/time_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

class StartTextField extends StatelessWidget {
  const StartTextField({
    super.key,
    required this.includeTime,
    required this.timeFormat,
    this.timeHintText,
    this.parseEndTimeError,
    this.parseTimeError,
    this.timeStr,
    this.endTimeStr,
    this.popoverMutex,
    this.onSubmitted,
  });

  final bool includeTime;
  final TimeFormatPB timeFormat;
  final String? timeHintText;
  final String? parseEndTimeError;
  final String? parseTimeError;
  final String? timeStr;
  final String? endTimeStr;
  final PopoverMutex? popoverMutex;
  final Function(String timeStr)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: includeTime
          ? TimeTextField(
              isEndTime: false,
              timeFormat: timeFormat,
              timeHintText: timeHintText,
              parseEndTimeError: parseEndTimeError,
              parseTimeError: parseTimeError,
              timeStr: timeStr,
              endTimeStr: endTimeStr,
              popoverMutex: popoverMutex,
              onSubmitted: onSubmitted,
            )
          : const SizedBox.shrink(),
    );
  }
}
