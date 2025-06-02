import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class TurnIntoMemberWidget extends StatelessWidget {
  const TurnIntoMemberWidget({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFGhostButton.normal(
      onTap: onTap,
      padding: EdgeInsets.all(theme.spacing.s),
      builder: (context, isHovering, disabled) {
        return FlowySvg(FlowySvgs.turn_into_member_m);
      },
    );
  }
}
