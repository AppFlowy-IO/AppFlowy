import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NameTextField extends StatefulWidget {
  final void Function(String) onDone;
  final void Function() onCanceled;
  final String name;

  const NameTextField({
    required this.name,
    required this.onDone,
    required this.onCanceled,
    Key? key,
  }) : super(key: key);

  @override
  State<NameTextField> createState() => _NameTextFieldState();
}

class _NameTextFieldState extends State<NameTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.name);

    _focusNode.addListener(notifyDidEndEditing);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedInputField(
        controller: _controller,
        focusNode: _focusNode,
        height: 36,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        normalBorderColor: theme.shader4,
        errorBorderColor: theme.red,
        focusBorderColor: theme.main1,
        cursorColor: theme.main1,
        onChanged: (text) {
          print(text);
        });
  }

  @override
  void dispose() {
    _focusNode.removeListener(notifyDidEndEditing);
    super.dispose();
  }

  void notifyDidEndEditing() {
    if (_controller.text.isEmpty) {
      // widget.onCanceled();
    } else {
      widget.onDone(_controller.text);
    }
  }
}
