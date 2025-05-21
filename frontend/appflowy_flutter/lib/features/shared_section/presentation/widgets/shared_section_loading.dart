import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class SharedSectionLoading extends StatelessWidget {
  const SharedSectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Center(
      child: CircularProgressIndicator(
        color: theme.iconColorScheme.primary,
      ),
    );
  }
}
