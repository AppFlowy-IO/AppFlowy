import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FlowyTextButton extends StatelessWidget {
  final String text;
  final double fontSize;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  const FlowyTextButton(this.text,
      {Key? key,
      this.onPressed,
      this.fontSize = 16,
      this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return InkWell(
      onTap: onPressed,
      child: FlowyHover(
        config: HoverDisplayConfig(borderRadius: BorderRadius.circular(6), hoverColor: theme.bg3),
        builder: (context, onHover) => _render(),
      ),
    );
  }

  Widget _render() {
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlowyText(text, fontSize: fontSize),
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