import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FieldNameTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedInputField(
      height: 36,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      initialValue: name,
      normalBorderColor: theme.shader4,
      errorBorderColor: theme.red,
      focusBorderColor: theme.main1,
      cursorColor: theme.main1,
      errorText: errorText,
      onChanged: onNameChanged,
    );
  }
}
