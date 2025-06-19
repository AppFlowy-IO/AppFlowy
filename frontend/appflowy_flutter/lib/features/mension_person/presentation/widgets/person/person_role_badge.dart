import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class PersonRoleBadge extends StatelessWidget {
  const PersonRoleBadge({
    super.key,
    required this.person,
    required this.access,
  });

  final Person person;
  final bool access;
  PersonRole get role => person.role;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    double paddingLeft = spacing.xs;
    if (role == PersonRole.contact || person.deleted) {
      paddingLeft = spacing.m;
    }
    final noAccess =
        !access && !person.deleted && person.role != PersonRole.contact;
    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.spacing.s),
        border: Border.all(color: theme.borderColorScheme.primary),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(paddingLeft, 2, spacing.m, 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildPrefix(context),
            buildText(context),
          ],
        ),
      ),
    );
    if (noAccess) {
      child = FlowyTooltip(
        message: LocaleKeys.document_mentionMenu_noAccessTooltip.tr(),
        preferBelow: false,
        child: child,
      );
    }
    return child;
  }

  Widget buildPrefix(BuildContext context) {
    if (person.deleted) return const SizedBox.shrink();
    if (role == PersonRole.contact) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context);
    if (!access) {
      return FlowySvg(
        FlowySvgs.person_icon_no_access_m,
        size: Size.square(20),
        color: theme.iconColorScheme.tertiary,
      );
    }
    return buildDot(context);
  }

  Widget buildText(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    if (person.deleted) {
      return Text(
        LocaleKeys.document_mentionMenu_deletedAccount.tr(),
        style: theme.textStyle.body
            .standard(color: theme.textColorScheme.tertiary),
      );
    }
    Color textColor = color(context);
    if (!access) {
      textColor = theme.textColorScheme.tertiary;
    }
    return Text(
      role.displayName(),
      style: theme.textStyle.body.standard(color: textColor),
    );
  }

  Widget buildDot(BuildContext context) {
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
