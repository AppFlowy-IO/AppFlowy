import 'dart:async';

import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlowyTextField extends StatefulWidget {
  final String? hintText;
  final String? text;
  final TextStyle? textStyle;
  final void Function(String)? onChanged;
  final void Function()? onEditingComplete;
  final void Function(String)? onSubmitted;
  final void Function()? onCanceled;
  final FocusNode? focusNode;
  final bool autoFocus;
  final int? maxLength;
  final TextEditingController? controller;
  final bool autoClearWhenDone;
  final bool submitOnLeave;
  final Duration? debounceDuration;
  final String? errorText;
  final Widget? error;
  final int? maxLines;
  final bool showCounter;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;
  final BoxConstraints? hintTextConstraints;
  final TextStyle? hintStyle;
  final InputDecoration? decoration;
  final TextAlignVertical? textAlignVertical;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const FlowyTextField({
    super.key,
    this.hintText = "",
    this.text,
    this.textStyle,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onCanceled,
    this.focusNode,
    this.autoFocus = true,
    this.maxLength,
    this.controller,
    this.autoClearWhenDone = false,
    this.submitOnLeave = false,
    this.debounceDuration,
    this.errorText,
    this.error,
    this.maxLines = 1,
    this.showCounter = true,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.hintTextConstraints,
    this.hintStyle,
    this.decoration,
    this.textAlignVertical,
    this.keyboardType = TextInputType.multiline,
    this.inputFormatters,
  });

  @override
  State<FlowyTextField> createState() => FlowyTextFieldState();
}

class FlowyTextFieldState extends State<FlowyTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;
  Timer? _debounceOnChanged;

  @override
  void initState() {
    super.initState();

    focusNode = widget.focusNode ?? FocusNode();
    focusNode.addListener(notifyDidEndEditing);

    controller = widget.controller ?? TextEditingController();

    if (widget.text != null) {
      controller.text = widget.text!;
    }

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
        if (widget.controller == null) {
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(notifyDidEndEditing);
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    if (widget.controller == null) {
      controller.dispose();
    }
    _debounceOnChanged?.cancel();
    super.dispose();
  }

  void _debounceOnChangedText(Duration duration, String text) {
    _debounceOnChanged?.cancel();
    _debounceOnChanged = Timer(duration, () async {
      if (mounted) {
        _onChanged(text);
      }
    });
  }

  void _onChanged(String text) {
    widget.onChanged?.call(text);
    setState(() {});
  }

  void _onSubmitted(String text) {
    widget.onSubmitted?.call(text);
    if (widget.autoClearWhenDone) {
      // using `controller.clear()` instead of `controller.text = ''` which will crash on Windows.
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (text) {
        if (widget.debounceDuration != null) {
          _debounceOnChangedText(widget.debounceDuration!, text);
        } else {
          _onChanged(text);
        }
      },
      onSubmitted: (text) => _onSubmitted(text),
      onEditingComplete: widget.onEditingComplete,
      minLines: 1,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      style: widget.textStyle ?? Theme.of(context).textTheme.bodySmall,
      textAlignVertical: widget.textAlignVertical ?? TextAlignVertical.center,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      decoration: widget.decoration ??
          InputDecoration(
            constraints: widget.hintTextConstraints ??
                BoxConstraints(
                  maxHeight: widget.errorText?.isEmpty ?? true ? 32 : 58,
                ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical:
                  (widget.maxLines == null || widget.maxLines! > 1) ? 12 : 0,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
              borderRadius: Corners.s8Border,
            ),
            isDense: false,
            hintText: widget.hintText,
            errorText: widget.errorText,
            error: widget.error,
            errorStyle: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).colorScheme.error),
            hintStyle: widget.hintStyle ??
                Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: Theme.of(context).hintColor),
            suffixText: widget.showCounter ? _suffixText() : "",
            counterText: "",
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.0,
              ),
              borderRadius: Corners.s8Border,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.0,
              ),
              borderRadius: Corners.s8Border,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.0,
              ),
              borderRadius: Corners.s8Border,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            prefixIconConstraints: widget.prefixIconConstraints,
            suffixIconConstraints: widget.suffixIconConstraints,
          ),
    );
  }

  void notifyDidEndEditing() {
    if (!focusNode.hasFocus) {
      if (controller.text.isNotEmpty && widget.submitOnLeave) {
        widget.onSubmitted?.call(controller.text);
      } else {
        widget.onCanceled?.call();
      }
    }
  }

  String? _suffixText() {
    if (widget.maxLength != null) {
      return ' ${controller.text.length}/${widget.maxLength}';
    }
    return null;
  }
}
