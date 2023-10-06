import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotificationViewActions extends StatefulWidget {
  const NotificationViewActions({
    super.key,
    required this.onSortChanged,
    this.onUnreadOnlyChanged,
    this.showUnreadOnlyAction = false,
  });

  final void Function(bool sortDescending) onSortChanged;
  final void Function(bool unreadOnly)? onUnreadOnlyChanged;
  final bool showUnreadOnlyAction;

  @override
  State<NotificationViewActions> createState() =>
      _NotificationViewActionsState();
}

class _NotificationViewActionsState extends State<NotificationViewActions> {
  bool sortDescending = true;
  bool unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.showUnreadOnlyAction ? 1 : 0,
          child: FlowyIconButton(
            tooltipText: unreadOnly
                ? LocaleKeys.notificationHub_actions_filterAll.tr()
                : LocaleKeys.notificationHub_actions_filterUnreadOnly.tr(),
            isSelected: unreadOnly,
            width: 24,
            height: 24,
            iconPadding: const EdgeInsets.all(3),
            iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
            icon: const FlowySvg(FlowySvgs.filter_s),
            onPressed: () {
              setState(() => unreadOnly = !unreadOnly);
              widget.onUnreadOnlyChanged?.call(unreadOnly);
            },
          ),
        ),
        const HSpace(4),
        FlowyIconButton(
          tooltipText: sortDescending
              ? LocaleKeys.notificationHub_actions_sortByAscending.tr()
              : LocaleKeys.notificationHub_actions_sortByDescending.tr(),
          width: 24,
          height: 24,
          iconPadding: const EdgeInsets.all(3),
          iconColorOnHover: Theme.of(context).colorScheme.onSecondary,
          icon: FlowySvg(
            sortDescending ? FlowySvgs.sort_high_s : FlowySvgs.sort_low_s,
          ),
          onPressed: () {
            setState(() => sortDescending = !sortDescending);
            widget.onSortChanged(sortDescending);
          },
        ),
      ],
    );
  }
}
