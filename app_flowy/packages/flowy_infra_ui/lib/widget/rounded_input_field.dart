import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/text_field_container.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class RoundedInputField extends StatefulWidget {
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final Widget? obscureIcon;
  final Widget? obscureHideIcon;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color normalBorderColor;
  final Color highlightBorderColor;
  final String errorText;
  final ValueChanged<String>? onChanged;
  late bool enableObscure;
  var _text = "";

  RoundedInputField({
    Key? key,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.obscureIcon,
    this.obscureHideIcon,
    this.onChanged,
    this.normalBorderColor = Colors.transparent,
    this.highlightBorderColor = Colors.transparent,
    this.fontWeight = FontWeight.normal,
    this.fontSize = 20,
    this.errorText = "",
  }) : super(key: key) {
    enableObscure = obscureText;
  }

  @override
  State<RoundedInputField> createState() => _RoundedInputFieldState();
}

class _RoundedInputFieldState extends State<RoundedInputField> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final Icon? newIcon = widget.icon == null
        ? null
        : Icon(
            widget.icon!,
            color: const Color(0xFF6F35A5),
          );

    var borderColor = widget.normalBorderColor;
    if (widget.errorText.isNotEmpty) {
      borderColor = widget.highlightBorderColor;
    }

    List<Widget> children = [
      TextFieldContainer(
        height: 48,
        borderRadius: BorderRadius.circular(10),
        borderColor: borderColor,
        child: TextFormField(
          onChanged: (value) {
            widget._text = value;
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            setState(() {});
          },
          cursorColor: theme.main1,
          obscureText: widget.enableObscure,
          decoration: InputDecoration(
            icon: newIcon,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: widget.normalBorderColor),
            border: InputBorder.none,
            suffixIcon: suffixIcon(),
          ),
        ),
      ),
    ];

    if (widget.errorText.isNotEmpty) {
      children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.errorText,
            style: TextStyle(
                color: widget.highlightBorderColor,
                fontWeight: widget.fontWeight,
                fontSize: widget.fontSize),
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: .4.seconds,
      curve: Curves.easeInOut,
      child: Column(
        children: children,
      ),
    );
  }

  Widget? suffixIcon() {
    if (widget.obscureText == false) {
      return null;
    }

    if (widget._text.isEmpty) {
      return SizedBox.fromSize(size: const Size.square(16));
    }

    Widget? icon;
    if (widget.obscureText == true) {
      assert(widget.obscureIcon != null && widget.obscureHideIcon != null);
      if (widget.enableObscure) {
        icon = widget.obscureIcon!;
      } else {
        icon = widget.obscureHideIcon!;
      }
    }

    if (icon == null) {
      return null;
    }

    return RoundedImageButton(
      size: 16,
      press: () {
        widget.enableObscure = !widget.enableObscure;
        setState(() {});
      },
      child: icon,
    );
  }
}
