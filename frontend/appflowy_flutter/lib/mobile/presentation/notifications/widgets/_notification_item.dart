import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(reminder: reminder),
          const HSpace(12.0),
          _NotificationContent(reminder: reminder),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return const FlowySvg(
      FlowySvgs.m_notification_reminder_s,
      size: Size.square(36),
      blendMode: null,
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        FlowyText.semibold(
          reminder.title,
          fontSize: 14,
          figmaLineHeight: 20,
        ),
        // time & page name
        FlowyText(
          reminder.toString(),
          maxLines: 20,
        ),
        // content
      ],
    );
  }
}
