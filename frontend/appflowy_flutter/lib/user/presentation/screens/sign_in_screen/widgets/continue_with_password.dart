import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ContinueWithPassword extends StatelessWidget {
  const ContinueWithPassword({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(),
      child: AFOutlinedTextButton.normal(
        text: 'Continue with password',
        size: AFButtonSize.l,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.xl,
          vertical: 10,
        ),
        onTap: onTap,
      ),
    );
  }
}
