import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class SharedSectionHeader extends StatelessWidget {
  const SharedSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: theme.spacing.xs,
        bottom: theme.spacing.s,
      ),
      child: Text(
        'Shared', // TODO: i18n
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.tertiary,
        ),
      ),
    );
  }
}
