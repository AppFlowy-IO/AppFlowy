import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
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
              role.displayName(),
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
    final theme = AppFlowyTheme.of(context),
        isLight = Theme.of(context).isLightMode;
    switch (role) {
      case PersonRole.member:
        return isLight
            ? theme.badgeColorScheme.color15Thick2
            : theme.badgeColorScheme.color15Thick1;
      case PersonRole.guest:
        return isLight
            ? theme.badgeColorScheme.color3Thick2
            : theme.badgeColorScheme.color3Thick1;
      case PersonRole.contact:
        return theme.textColorScheme.tertiary;
    }
  }
}

extension PersonRoleBadgeStringExtension on PersonRole {
  String displayName() {
    switch (this) {
      case PersonRole.member:
        return LocaleKeys.document_mentionMenu_member.tr();
      case PersonRole.guest:
        return LocaleKeys.document_mentionMenu_guest.tr();
      case PersonRole.contact:
        return LocaleKeys.document_mentionMenu_contact.tr();
    }
  }
}
