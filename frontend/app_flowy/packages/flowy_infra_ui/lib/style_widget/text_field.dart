import 'dart:async';

import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class FlowyTextField extends StatefulWidget {
  final String hintText;
  final String text;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onCanceled;
  final bool autoFocus;
  final int? maxLength;
  final TextEditingController? controller;
  final bool autoClearWhenDone;
  final Duration? debounceDuration;

  const FlowyTextField({
    this.hintText = "",
    this.text = "",
    this.onChanged,
    this.onSubmitted,
    this.onCanceled,
    this.autoFocus = true,
    this.maxLength,
    this.controller,
    this.autoClearWhenDone = false,
    this.debounceDuration,
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
    focusNode = FocusNode();
    focusNode.addListener(notifyDidEndEditing);

    if (widget.controller != null) {
      controller = widget.controller!;
    } else {
      controller = TextEditingController();
      controller.text = widget.text;
    }
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
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
      controller.text = "";
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
      maxLines: 1,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s10Border,
        ),
        isDense: true,
        hintText: widget.hintText,
        hintStyle: Theme.of(context)
            .textTheme
            .bodySmall!
            .textColor(Theme.of(context).hintColor),
        suffixText: _suffixText(),
        counterText: "",
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
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
    focusNode.dispose();
    super.dispose();
  }

  void notifyDidEndEditing() {
    if (!focusNode.hasFocus) {
      if (controller.text.isEmpty) {
        widget.onCanceled?.call();
      } else {
        widget.onSubmitted?.call(controller.text);
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
