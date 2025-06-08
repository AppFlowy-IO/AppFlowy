import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class PersonRoleBadge extends StatelessWidget {
  const PersonRoleBadge({super.key, required this.role});

  final PersonRole role;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    final paddingLeft = role == PersonRole.contact ? spacing.m : spacing.xs;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.spacing.s),
        border: Border.all(color: theme.borderColorScheme.primary),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(paddingLeft, 2, spacing.m, 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildDot(context),
            Text(
              role.name.capitalize(),
              style: theme.textStyle.body.standard(
                color: color(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDot(BuildContext context) {
    if (role == PersonRole.contact) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;

    return SizedBox.square(
      dimension: 20,
      child: Center(
        child: Container(
          width: spacing.m,
          height: spacing.m,
          decoration: BoxDecoration(
            color: color(context),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Color color(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    switch (role) {
      case PersonRole.member:
        return theme.badgeColorScheme.color15Thick2;
      case PersonRole.guest:
        return theme.badgeColorScheme.color3Thick2;
      case PersonRole.contact:
        return theme.textColorScheme.tertiary;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
