import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class VerifyingButton extends StatelessWidget {
  const VerifyingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Opacity(
      opacity: 0.7,
      child: AFFilledButton.disabled(
        size: AFButtonSize.l,
        backgroundColor: theme.fillColorScheme.themeThick,
        builder: (context, isHovering, disabled) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 15.0,
                child: CircularProgressIndicator(
                  color: theme.textColorScheme.onFill,
                  strokeWidth: 3.0,
                ),
              ),
              HSpace(theme.spacing.l),
              Text(
                'Verifying...', //
                style: theme.textStyle.body.enhanced(
                  color: theme.textColorScheme.onFill,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
