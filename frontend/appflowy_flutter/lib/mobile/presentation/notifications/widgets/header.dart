import 'package:appflowy/mobile/presentation/notifications/widgets/settings_popup_menu.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileNotificationPageHeader extends StatelessWidget {
  const MobileNotificationPageHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HSpace(16.0),
          FlowyText(
            'Notifications',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          Spacer(),
          NotificationSettingsPopupMenu(),
          HSpace(16.0),
        ],
      ),
    );
  }
}
