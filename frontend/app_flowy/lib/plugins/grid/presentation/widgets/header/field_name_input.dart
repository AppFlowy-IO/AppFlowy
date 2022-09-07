import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FieldNameTextField extends StatefulWidget {
  final void Function(String) onNameChanged;
  final String name;
  final String errorText;
  const FieldNameTextField({
    required this.name,
    required this.errorText,
    required this.onNameChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<FieldNameTextField> {
  late String name;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.name;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedInputField(
      height: 36,
      autoFocus: true,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      controller: controller,
      normalBorderColor: theme.shader4,
      errorBorderColor: theme.red,
      focusBorderColor: theme.main1,
      cursorColor: theme.main1,
      errorText: widget.errorText,
      onChanged: widget.onNameChanged,
    );
  }

  @override
  void didUpdateWidget(covariant FieldNameTextField oldWidget) {
    controller.text = widget.name;
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));

    super.didUpdateWidget(oldWidget);
  }
}
