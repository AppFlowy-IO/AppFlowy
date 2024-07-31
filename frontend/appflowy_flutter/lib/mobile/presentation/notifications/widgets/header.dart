import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/settings_popup_menu.dart';
import 'package:easy_localization/easy_localization.dart';
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(16.0),
          FlowyText(
            LocaleKeys.settings_notifications_titles_notifications.tr(),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          const Spacer(),
          const NotificationSettingsPopupMenu(),
          const HSpace(16.0),
        ],
      ),
    );
  }
}
