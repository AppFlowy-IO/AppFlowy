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
  final bool autoFucous;
  final int? maxLength;
  final TextEditingController? controller;
  final bool autoClearWhenDone;
  const FlowyTextField({
    this.hintText = "",
    this.text = "",
    this.onChanged,
    this.onSubmitted,
    this.onCanceled,
    this.autoFucous = true,
    this.maxLength,
    this.controller,
    this.autoClearWhenDone = false,
    Key? key,
  }) : super(key: key);

  @override
  State<FlowyTextField> createState() => FlowyTextFieldState();
}

class FlowyTextFieldState extends State<FlowyTextField> {
  late FocusNode focusNode;
  late TextEditingController controller;
  var textLength = 0;

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
    if (widget.autoFucous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (text) {
        widget.onChanged?.call(text);
      },
      onSubmitted: (text) {
        widget.onSubmitted?.call(text);

        if (widget.autoClearWhenDone) {
          controller.text = "";
        }
      },
      maxLines: 1,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      style: TextStyles.body1.size(FontSizes.s12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: Corners.s10Border,
        ),
        isDense: true,
        hintText: widget.hintText,
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
      return '${textLength.toString()}/${widget.maxLength.toString()}';
    } else {
      return null;
    }
  }
}
