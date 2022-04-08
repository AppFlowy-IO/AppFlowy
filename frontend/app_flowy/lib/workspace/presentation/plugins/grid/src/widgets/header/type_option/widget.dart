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
  var isEdited = false;
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
      autoFocus: true,
      height: 36,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      normalBorderColor: theme.shader4,
      focusBorderColor: theme.main1,
      cursorColor: theme.main1,
      onEditingComplete: () {
        widget.onDone(_controller.text);
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(notifyDidEndEditing);
    _focusNode.dispose();
    super.dispose();
  }

  void notifyDidEndEditing() {
    if (!_focusNode.hasFocus) {
      if (_controller.text.isEmpty) {
        widget.onCanceled();
      } else {
        widget.onDone(_controller.text);
      }
    }
  }
}

class TypeOptionSeparator extends StatelessWidget {
  const TypeOptionSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        color: theme.shader4,
        height: 0.25,
      ),
    );
  }
}
