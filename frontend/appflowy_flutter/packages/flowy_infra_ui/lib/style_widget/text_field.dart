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
  final int maxLines;

  const FlowyTextField({
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
    this.maxLines = 1,
    Key? key,
  }) : super(key: key);

  @override
  State<FlowyTextField> createState() => FlowyTextFieldState();
}

class FlowyTextFieldState extends State<FlowyTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;
  Timer? _debounceOnChanged;

  @override
  void initState() {
    focusNode = widget.focusNode ?? FocusNode();
    focusNode.addListener(notifyDidEndEditing);

    controller = widget.controller ?? TextEditingController();
    if (widget.text != null) {
      controller.text = widget.text!;
    }

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
        controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));
      });
    }
    super.initState();
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
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      style: widget.textStyle ?? Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        constraints: BoxConstraints(
            maxHeight: widget.errorText?.isEmpty ?? true ? 32 : 58),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        errorStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: Theme.of(context).colorScheme.error),
        hintStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(color: Theme.of(context).hintColor),
        suffixText: _suffixText(),
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
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(notifyDidEndEditing);
    if (widget.focusNode == null) {
      focusNode.dispose();
    }
    super.dispose();
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
    } else {
      return null;
    }
  }
}
