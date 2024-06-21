import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';

/// This is used to describe a settings input field
///
/// The input will have secondary action of "save" and "cancel"
/// which will only be shown when the input has changed.
///
/// _Note: The label can overflow and will be ellipsized._
///
class SettingsInputField extends StatefulWidget {
  const SettingsInputField({
    super.key,
    this.label,
    this.textController,
    this.focusNode,
    this.obscureText = false,
    this.value,
    this.placeholder,
    this.tooltip,
    this.onSave,
    this.onCancel,
    this.hideActions = false,
    this.onChanged,
  });

  final String? label;
  final TextEditingController? textController;
  final FocusNode? focusNode;

  /// If true, the input field will be obscured
  /// and an option to toggle to show the text will be provided.
  ///
  final bool obscureText;

  final String? value;
  final String? placeholder;
  final String? tooltip;

  /// If true the save and cancel options will not show below the
  /// input field.
  ///
  final bool hideActions;

  final void Function(String)? onSave;

  /// The action to be performed when the cancel button is pressed.
  ///
  /// If null the button will **NOT** be disabled! Instead it will
  /// reset the input to the original value.
  ///
  final void Function()? onCancel;

  final void Function(String)? onChanged;

  @override
  State<SettingsInputField> createState() => _SettingsInputFieldState();
}

class _SettingsInputFieldState extends State<SettingsInputField> {
  late final controller =
      widget.textController ?? TextEditingController(text: widget.value);
  late final FocusNode focusNode = widget.focusNode ?? FocusNode();
  late bool obscureText = widget.obscureText;

  @override
  void dispose() {
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    if (widget.textController == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (widget.label?.isNotEmpty == true) ...[
              Flexible(
                child: FlowyText.medium(
                  widget.label!,
                  color: AFThemeExtension.of(context).secondaryTextColor,
                ),
              ),
            ],
            if (widget.tooltip != null) ...[
              const HSpace(4),
              FlowyTooltip(
                message: widget.tooltip,
                child: const FlowySvg(FlowySvgs.information_s),
              ),
            ],
          ],
        ),
        if (widget.label?.isNotEmpty ?? false || widget.tooltip != null)
          const VSpace(8),
        SizedBox(
          height: 48,
          child: FlowyTextField(
            focusNode: focusNode,
            hintText: widget.placeholder,
            controller: controller,
            autoFocus: false,
            obscureText: obscureText,
            isDense: false,
            suffixIconConstraints:
                BoxConstraints.tight(const Size(23 + 18, 24)),
            suffixIcon: !widget.obscureText
                ? null
                : GestureDetector(
                    onTap: () => setState(() => obscureText = !obscureText),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: FlowySvg(
                        obscureText ? FlowySvgs.show_m : FlowySvgs.hide_m,
                        size: const Size(12, 15),
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
            onSubmitted: widget.onSave,
            onChanged: (_) {
              widget.onChanged?.call(controller.text);
              setState(() {});
            },
          ),
        ),
        if (!widget.hideActions &&
            ((widget.value == null && controller.text.isNotEmpty) ||
                widget.value != null && widget.value != controller.text)) ...[
          const VSpace(8),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                height: 21,
                child: FlowyTextButton(
                  LocaleKeys.button_save.tr(),
                  fontWeight: FontWeight.normal,
                  padding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  fontColor: AFThemeExtension.of(context).textColor,
                  onPressed: () => widget.onSave?.call(controller.text),
                ),
              ),
              const HSpace(24),
              SizedBox(
                height: 21,
                child: FlowyTextButton(
                  LocaleKeys.button_cancel.tr(),
                  fontWeight: FontWeight.normal,
                  padding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  fontColor: AFThemeExtension.of(context).textColor,
                  onPressed: () {
                    setState(() => controller.text = widget.value ?? '');
                    widget.onCancel?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
