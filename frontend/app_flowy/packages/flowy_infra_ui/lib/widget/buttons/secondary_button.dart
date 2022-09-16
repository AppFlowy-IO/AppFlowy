import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'base_styled_button.dart';

class SecondaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const SecondaryTextButton(this.label,
      {Key? key, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SecondaryButton(
      bigMode: bigMode,
      onPressed: onPressed,
      child: FlowyText.regular(
        label,
        color: theme.main1,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool bigMode;

  const SecondaryButton(
      {Key? key, required this.child, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BaseStyledButton(
      minWidth: bigMode ? 100 : 80,
      minHeight: bigMode ? 40 : 38,
      contentPadding: EdgeInsets.zero,
      bgColor: theme.shader7,
      hoverColor: theme.hover,
      downColor: theme.main1,
      outlineColor: theme.main1,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      onPressed: onPressed,
      child: child,
    );
  }
}
