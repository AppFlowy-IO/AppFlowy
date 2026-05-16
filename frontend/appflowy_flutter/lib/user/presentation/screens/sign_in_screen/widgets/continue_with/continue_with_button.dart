import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ContinueWithButton extends StatelessWidget {
  const ContinueWithButton({
    super.key,
    required this.onTap,
    required this.text,
  });

  final VoidCallback onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFFilledTextButton.primary(
      size: AFButtonSize.l,
      alignment: Alignment.center,
      text: text,
      onTap: onTap,
      textStyle: theme.textStyle.body.enhanced(
        color: theme.textColorScheme.onFill,
      ),
    );
  }
}
