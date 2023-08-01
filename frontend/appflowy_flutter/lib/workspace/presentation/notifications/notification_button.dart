import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: const BoxConstraints(maxHeight: 250, maxWidth: 300),
      // TODO(Xazin): Reminder/Notifications - Continue work here
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      child: FlowyText.semibold(
                        'Notifications',
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
      child: const FlowyIconButton(
        // TODO(Xazin): Localize
        tooltipText: 'Notifications',
        width: 24,
        icon: Icon(Icons.notifications_outlined),
      ),
    );
  }
}
