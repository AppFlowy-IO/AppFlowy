import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class TimeOptions {
  const TimeOptions({
    required this.timeFormat,
    this.timeHintText,
    this.parseTimeError,
    this.timeStr,
    this.onSubmitted,
  });

  final TimeFormatPB timeFormat;
  final String? timeHintText;
  final String? parseTimeError;
  final String? timeStr;
  final Function(String timeStr)? onSubmitted;
}

class DateOptions {
  DateOptions({
    required this.dateFormat,
    required this.date,
  });

  final DateFormatPB dateFormat;
  final DateTime? date;
}

class DateTimeInput extends StatelessWidget {
  const DateTimeInput({
    super.key,
    this.popoverMutex,
    this.isTimeEnabled = true,
    required this.dateOptions,
    this.timeOptions,
  }) : assert(!isTimeEnabled || timeOptions != null);

  final PopoverMutex? popoverMutex;
  final bool isTimeEnabled;

  final DateOptions dateOptions;
  final TimeOptions? timeOptions;

  @override
  Widget build(BuildContext context) {
    final inputDecoration = _defaultInputDecoration(context);
    final leftBorder = _inputBorderFromSide(context, true);
    final rightBorder = _inputBorderFromSide(context, false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: Corners.s8Border,
            ),
            child: Row(
              children: [
                Flexible(
                  child: _DatePart(
                    inputDecoration: isTimeEnabled
                        ? inputDecoration.copyWith(
                            enabledBorder: leftBorder,
                            focusedBorder: leftBorder,
                          )
                        : inputDecoration,
                    options: dateOptions,
                  ),
                ),
                if (isTimeEnabled && timeOptions != null) ...[
                  SizedBox(
                    height: 18,
                    child: VerticalDivider(
                      width: 4,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Flexible(
                    child: _TimePart(
                      inputDecoration: isTimeEnabled
                          ? inputDecoration.copyWith(
                              enabledBorder: rightBorder,
                              focusedBorder: rightBorder,
                            )
                          : inputDecoration,
                      options: timeOptions!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (timeOptions?.parseTimeError?.isNotEmpty ?? false) ...[
            const VSpace(4),
            Text(
              timeOptions!.parseTimeError!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  InputBorder _inputBorderFromSide(BuildContext context, bool isLeft) =>
      OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? Corners.s8Radius : Radius.zero,
          bottomLeft: isLeft ? Corners.s8Radius : Radius.zero,
          topRight: !isLeft ? Corners.s8Radius : Radius.zero,
          bottomRight: !isLeft ? Corners.s8Radius : Radius.zero,
        ),
      );

  InputDecoration _defaultInputDecoration(BuildContext context) =>
      InputDecoration(
        constraints: const BoxConstraints(maxHeight: 32),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          borderRadius: Corners.s8Border,
        ),
        isDense: false,
        errorStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: Theme.of(context).colorScheme.error),
        hintStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: Theme.of(context).hintColor),
        suffixText: "",
        counterText: "",
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          borderRadius: Corners.s8Border,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          borderRadius: Corners.s8Border,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          borderRadius: Corners.s8Border,
        ),
      );
}

class _DatePart extends StatefulWidget {
  const _DatePart({
    required this.inputDecoration,
    required this.options,
  });

  final InputDecoration inputDecoration;
  final DateOptions options;

  @override
  State<_DatePart> createState() => _DatePartState();
}

class _DatePartState extends State<_DatePart> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final dateStr = widget.options.date != null
        ? widget.options.dateFormat.formatDate(
            widget.options.date!,
            false,
          )
        : "";

    _controller = TextEditingController(text: dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return FlowyTextField(
      controller: _controller,
      decoration: widget.inputDecoration,
    );
  }
}

class _TimePart extends StatefulWidget {
  const _TimePart({
    required this.inputDecoration,
    required this.options,
  });

  final InputDecoration inputDecoration;
  final TimeOptions options;

  @override
  State<_TimePart> createState() => _TimePartState();
}

class _TimePartState extends State<_TimePart> {
  late final _controller = TextEditingController(text: widget.options.timeStr);

  @override
  Widget build(BuildContext context) {
    return FlowyTextField(
      controller: _controller,
      decoration: widget.inputDecoration,
      onSubmitted: widget.options.onSubmitted,
    );
  }
}
