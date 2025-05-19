import 'package:appflowy/features/share/presentation/widgets/shared_group_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class GeneralAccessSection extends StatelessWidget {
  const GeneralAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenuSection(
      title: 'General access',
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
      ),
      children: [
        SharedGroupWidget(),
      ],
    );
  }
}
