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
    this.icon,
    this.obscureText = false,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Icon? newIcon = icon == null
        ? null
        : Icon(
            icon!,
            color: const Color(0xFF6F35A5),
          );

    return TextFieldContainer(
      borderRadius: BorderRadius.circular(10),
      borderColor: Colors.blueGrey,
      child: TextFormField(
        onChanged: onChanged,
        cursorColor: const Color(0xFF6F35A5),
        obscureText: obscureText,
        decoration: InputDecoration(
          icon: newIcon,
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
