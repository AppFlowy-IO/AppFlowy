import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class EditAccessLevelWidget extends StatelessWidget {
  const EditAccessLevelWidget({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFGhostButton.normal(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.l,
      ),
      builder: (context, isHovering, disabled) {
        return Row(
          children: [
            Text(
              title,
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
            HSpace(theme.spacing.xs),
            FlowySvg(
              FlowySvgs.arrow_down_s,
              color: theme.textColorScheme.secondary,
            ),
          ],
        );
      },
    );
  }
}
