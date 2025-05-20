import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class SharedSectionError extends StatelessWidget {
  const SharedSectionError({
    super.key,
    required this.errorMessage,
  });

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        errorMessage,
        style: theme.textStyle.body.enhanced(
          color: theme.textColorScheme.warning,
        ),
      ),
    );
  }
}
