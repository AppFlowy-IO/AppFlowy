import 'package:flowy_infra_ui/style_widget/styled_hover.dart';
import 'package:flowy_infra_ui/style_widget/styled_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StyledTextButton extends StatelessWidget {
  final String text;
  final double fontSize;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  const StyledTextButton(this.text,
      {Key? key,
      this.onPressed,
      this.fontSize = 16,
      this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: StyledHover(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        builder: (context, onHover) => _render(),
      ),
    );
  }

  Widget _render() {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: StyledText(text, fontSize: fontSize),
      ),
    );
  }
}
// return TextButton(
    //   style: ButtonStyle(
    //     textStyle: MaterialStateProperty.all(TextStyle(fontSize: fontSize)),
    //     alignment: Alignment.centerLeft,
    //     foregroundColor: MaterialStateProperty.all(Colors.black),
    //     padding: MaterialStateProperty.all<EdgeInsets>(
    //         const EdgeInsets.symmetric(horizontal: 2)),
    //   ),
    //   onPressed: onPressed,
    //   child: Text(
    //     text,
    //     overflow: TextOverflow.ellipsis,
    //     softWrap: false,
    //   ),
    // );