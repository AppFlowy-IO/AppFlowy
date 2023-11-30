import 'package:flutter/material.dart';

class MobileCardCellStyle {
  MobileCardCellStyle(this.context);

  BuildContext context;

  EdgeInsets get padding => const EdgeInsets.symmetric(
        vertical: 4,
      );

  TextStyle? primaryTextStyle() {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
      fontSize: 16,
      color: theme.colorScheme.onBackground,
    );
  }

  TextStyle? secondaryTextStyle() {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.tertiary,
      fontSize: 14,
    );
  }

  TextStyle? tagTextStyle() {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onBackground,
      fontSize: 12,
    );
  }

  TextStyle? urlTextStyle() {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontSize: 16,
      decoration: TextDecoration.underline,
    );
  }
}
