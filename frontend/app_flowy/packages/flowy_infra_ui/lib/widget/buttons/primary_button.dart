import 'package:flutter/material.dart';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'base_styled_button.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryTextButton(this.label, {Key? key, this.onPressed, this.bigMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle txtStyle = TextStyles.Footnote.textColor(Colors.white);
    return PrimaryButton(bigMode: bigMode, onPressed: onPressed, child: Text(label, style: txtStyle));
  }
}

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryButton({Key? key, required this.child, this.onPressed, this.bigMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseStyledButton(
      minWidth: bigMode ? 170 : 78,
      minHeight: bigMode ? 48 : 28,
      contentPadding: EdgeInsets.zero,
      bgColor: Theme.of(context).primaryColor,
      hoverColor: Theme.of(context).primaryColor,
      downColor: Theme.of(context).primaryColor,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      child: child,
      onPressed: onPressed,
    );
  }
}
