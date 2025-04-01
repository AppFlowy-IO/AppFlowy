import 'package:appflowy/theme/component/button/base.dart';
import 'package:appflowy/theme/component/button/filled_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class ContinueWithEmail extends StatelessWidget {
  const ContinueWithEmail({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFFilledPrimaryTextButton(
      text: 'Continue with email',
      size: AFButtonSize.l,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.xl,
        vertical: 10,
      ),
      onTap: onTap,
    );
  }
}
