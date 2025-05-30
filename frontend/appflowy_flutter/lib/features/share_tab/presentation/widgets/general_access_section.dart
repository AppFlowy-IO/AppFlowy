import 'package:appflowy/features/share_tab/data/models/shared_group.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/shared_group_widget.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class GeneralAccessSection extends StatelessWidget {
  const GeneralAccessSection({
    super.key,
    required this.group,
  });

  final SharedGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFMenuSection(
      title: 'General access',
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.xs,
        horizontal: theme.spacing.m,
      ),
      children: [
        SharedGroupWidget(
          group: group,
        ),
      ],
    );
  }
}
