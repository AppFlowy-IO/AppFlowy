import 'package:flowy_infra_ui/widget/text_field_container.dart';
import 'package:flutter/material.dart';

class RoundedInputField extends StatelessWidget {
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const RoundedInputField({
    Key? key,
    this.hintText,
    this.icon = Icons.person,
    this.obscureText = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
        child: TextFormField(
      onChanged: onChanged,
      cursorColor: const Color(0xFF6F35A5),
      obscureText: obscureText,
      decoration: InputDecoration(
        icon: Icon(
          icon,
          color: const Color(0xFF6F35A5),
        ),
        hintText: hintText,
        border: InputBorder.none,
      ),
    ));
  }
}
