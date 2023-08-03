import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO(Xazin): Reminder/Notifications - Continue work here
    return Tooltip(
      message: LocaleKeys.notificationHub_title.tr(),
      child: AppFlowyPopover(
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
        popupBuilder: (_) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        child: FlowyText.semibold(
                          LocaleKeys.notificationHub_title.tr(),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const VSpace(4),
              NotificationItem(
                onAction: () {},
              ),
              const NotificationItem(),
              const NotificationItem(),
              const NotificationItem(),
              const NotificationItem(),
            ],
          ),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
