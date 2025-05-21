import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class MobileSettingTrailing extends StatelessWidget {
  const MobileSettingTrailing({
    super.key,
    required this.text,
    this.showArrow = true,
  });

  final String text;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: theme.textStyle.heading4.standard(
              color: theme.textColorScheme.secondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showArrow) ...[
          const HSpace(8),
          FlowySvg(
            FlowySvgs.toolbar_arrow_right_m,
            size: Size.square(24),
            color: theme.iconColorScheme.tertiary,
          ),
        ],
      ],
    );
  }
}
