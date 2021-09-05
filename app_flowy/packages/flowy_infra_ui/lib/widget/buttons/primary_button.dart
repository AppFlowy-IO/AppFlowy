import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
import 'base_styled_button.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:textstyle_extensions/textstyle_extensions.dart';

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryButton(
      {Key? key, required this.child, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BaseStyledButton(
      minWidth: bigMode ? 160 : 78,
      minHeight: bigMode ? 60 : 42,
      contentPadding: EdgeInsets.all(bigMode ? Insets.l : Insets.m),
      bgColor: theme.bg1,
      hoverColor: theme.hover,
      downColor: theme.selector,
      borderRadius: bigMode ? Corners.s8 : Corners.s5,
      child: child,
      onPressed: onPressed,
    );
  }
}

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryTextButton(this.label,
      {Key? key, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle txtStyle = (bigMode ? TextStyles.Callout : TextStyles.Footnote)
        .textColor(Colors.white);
    return PrimaryButton(
        bigMode: bigMode,
        onPressed: onPressed,
        child: Text(label, style: txtStyle));
  }
}
