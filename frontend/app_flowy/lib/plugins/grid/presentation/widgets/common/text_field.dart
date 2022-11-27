import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class InputTextField extends StatefulWidget {
  final void Function(String)? onDone;
  final void Function(String)? onChanged;
  final void Function() onCanceled;
  final bool autoClearWhenDone;
  final String text;
  final int? maxLength;
  final FocusNode? focusNode;

  const InputTextField({
    required this.text,
    this.onDone,
    required this.onCanceled,
    this.onChanged,
    this.autoClearWhenDone = false,
    this.maxLength,
    this.focusNode,
    Key? key,
  }) : super(key: key);

  @override
  State<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends State<InputTextField> {
  late FocusNode _focusNode;
  var isEdited = false;
  late TextEditingController _controller;

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = TextEditingController(text: widget.text);
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _focusNode.requestFocus();
    });

    _focusNode.addListener(notifyDidEndEditing);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RoundedInputField(
      controller: _controller,
      focusNode: _focusNode,
      autoFocus: true,
      height: 36.0,
      maxLength: widget.maxLength,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (text) {
        if (widget.onChanged != null) {
          widget.onChanged!(text);
        }
      },
      onEditingComplete: (_) {
        if (widget.onDone != null) {
          widget.onDone!(_controller.text);
        }

        if (widget.autoClearWhenDone) {
          _controller.text = "";
        }
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(notifyDidEndEditing);
    // only dispose the focusNode if it was created in this widget's initState
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void notifyDidEndEditing() {
    if (!_focusNode.hasFocus) {
      if (_controller.text.isEmpty) {
        widget.onCanceled();
      } else {
        if (widget.onDone != null) {
          widget.onDone!(_controller.text);
        }
      }
    }
  }
}

class TypeOptionSeparator extends StatelessWidget {
  const TypeOptionSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        color: Theme.of(context).dividerColor,
        height: 1.0,
      ),
    );
  }
}
