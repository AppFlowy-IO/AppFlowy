import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/application/settings/date_time/time_patterns.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class IncludeTimeButton extends StatefulWidget {
  const IncludeTimeButton({
    super.key,
    this.initialTime,
    required this.popoverMutex,
    this.includeTime = false,
    this.onChanged,
    this.onSubmitted,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
  });

  final String? initialTime;
  final PopoverMutex? popoverMutex;
  final bool includeTime;
  final Function(bool includeTime)? onChanged;
  final Function(String? time)? onSubmitted;
  final UserTimeFormatPB timeFormat;

  @override
  State<IncludeTimeButton> createState() => _IncludeTimeButtonState();
}

class _IncludeTimeButtonState extends State<IncludeTimeButton> {
  late bool _includeTime = widget.includeTime;
  bool _showTimeTooltip = false;
  String? _timeString;

  @override
  void initState() {
    super.initState();
    _timeString = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_includeTime) ...[
          _TimeTextField(
            timeStr: _timeString,
            popoverMutex: widget.popoverMutex,
            timeFormat: widget.timeFormat,
            onSubmitted: (value) {
              setState(() => _timeString = value);
              widget.onSubmitted?.call(_timeString);
            },
          ),
          const TypeOptionSeparator(spacing: 12.0),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SizedBox(
            height: GridSize.popoverItemHeight,
            child: Padding(
              padding: GridSize.typeOptionContentInsets -
                  const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  FlowySvg(
                    FlowySvgs.clock_alarm_s,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const HSpace(6),
                  FlowyText.medium(LocaleKeys.grid_field_includeTime.tr()),
                  const HSpace(6),
                  FlowyTooltip(
                    message: LocaleKeys.datePicker_dateTimeFormatTooltip.tr(),
                    child: FlowyHover(
                      resetHoverOnRebuild: false,
                      style: HoverStyle(
                        foregroundColorOnHover:
                            Theme.of(context).colorScheme.primary,
                        borderRadius: Corners.s10Border,
                      ),
                      onHover: (isHovering) => setState(
                        () => _showTimeTooltip = isHovering,
                      ),
                      child: FlowyTextButton(
                        '?',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        fontColor: _showTimeTooltip
                            ? Theme.of(context).colorScheme.onSurface
                            : null,
                        fillColor: _showTimeTooltip
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        radius: Corners.s12Border,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Toggle(
                    value: _includeTime,
                    onChanged: (value) {
                      widget.onChanged?.call(!value);
                      setState(() => _includeTime = !value);
                    },
                    style: ToggleStyle.big,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _maxLengthTwelveHour = 8;
const _maxLengthTwentyFourHour = 5;

class _TimeTextField extends StatefulWidget {
  const _TimeTextField({
    required this.timeStr,
    required this.popoverMutex,
    this.onSubmitted,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
  });

  final String? timeStr;
  final PopoverMutex? popoverMutex;
  final Function(String? value)? onSubmitted;
  final UserTimeFormatPB timeFormat;

  @override
  State<_TimeTextField> createState() => _TimeTextFieldState();
}

class _TimeTextFieldState extends State<_TimeTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textController;

  late String? _timeString;

  String? errorText;

  @override
  void initState() {
    super.initState();

    _timeString = widget.timeStr;
    _focusNode = FocusNode();
    _textController = TextEditingController()..text = _timeString ?? "";

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });

    widget.popoverMutex?.listenOnPopoverChanged(() {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: FlowyTextField(
            text: _timeString ?? "",
            focusNode: _focusNode,
            controller: _textController,
            maxLength: widget.timeFormat == UserTimeFormatPB.TwelveHour
                ? _maxLengthTwelveHour
                : _maxLengthTwentyFourHour,
            showCounter: false,
            submitOnLeave: true,
            hintText: hintText,
            errorText: errorText,
            onSubmitted: (value) {
              setState(() {
                errorText = _validate(value);
              });

              if (errorText == null) {
                widget.onSubmitted?.call(value);
              }
            },
          ),
        ),
      ],
    );
  }

  String? _validate(String value) {
    final msg = LocaleKeys.grid_field_invalidTimeFormat.tr();

    switch (widget.timeFormat) {
      case UserTimeFormatPB.TwentyFourHour:
        if (!isTwentyFourHourTime(value)) {
          return "$msg. e.g. 13:00";
        }
      case UserTimeFormatPB.TwelveHour:
        if (!isTwelveHourTime(value)) {
          return "$msg. e.g. 01:00 PM";
        }
    }

    return null;
  }

  String get hintText => switch (widget.timeFormat) {
        UserTimeFormatPB.TwentyFourHour =>
          LocaleKeys.document_date_timeHintTextInTwentyFourHour.tr(),
        UserTimeFormatPB.TwelveHour =>
          LocaleKeys.document_date_timeHintTextInTwelveHour.tr(),
        _ => "",
      };
}
