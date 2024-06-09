import 'package:flutter/material.dart';

import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/time_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

class EndTextField extends StatelessWidget {
  const EndTextField({
    super.key,
    required this.includeTime,
    required this.isRange,
    required this.timeFormat,
    this.endTimeStr,
    this.popoverMutex,
    this.onSubmitted,
  });

  final bool includeTime;
  final bool isRange;
  final TimeFormatPB timeFormat;
  final String? endTimeStr;
  final PopoverMutex? popoverMutex;
  final Function(String timeStr)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: includeTime && isRange
          ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TimeTextField(
                isEndTime: true,
                timeFormat: timeFormat,
                endTimeStr: endTimeStr,
                popoverMutex: popoverMutex,
                onSubmitted: onSubmitted,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
