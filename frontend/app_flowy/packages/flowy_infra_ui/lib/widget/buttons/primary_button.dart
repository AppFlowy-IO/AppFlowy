import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'base_styled_button.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryTextButton(this.label, {Key? key, this.onPressed, this.bigMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle txtStyle = TextStyles.Btn.textColor(Colors.white);
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
    final theme = context.watch<AppTheme>();
    return BaseStyledButton(
      minWidth: bigMode ? 170 : 78,
      minHeight: bigMode ? 48 : 28,
      contentPadding: EdgeInsets.zero,
      bgColor: theme.main1,
      hoverColor: theme.main1,
      downColor: theme.main1,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      onPressed: onPressed,
      child: child,
    );
  }
}
