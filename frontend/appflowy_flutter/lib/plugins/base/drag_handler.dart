import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class DragHandle extends StatelessWidget {
  const DragHandle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class DragHandleV2 extends StatelessWidget {
  const DragHandleV2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      height: 4,
      width: 36,
      margin: EdgeInsets.symmetric(vertical: theme.spacing.s),
      decoration: BoxDecoration(
        color: theme.iconColorScheme.quaternary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
