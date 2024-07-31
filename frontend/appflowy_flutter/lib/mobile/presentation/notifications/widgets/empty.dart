import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmptyNotification extends StatelessWidget {
  const EmptyNotification({
    super.key,
    required this.type,
  });

  final MobileNotificationTabType type;

  @override
  Widget build(BuildContext context) {
    final title = switch (type) {
      MobileNotificationTabType.inbox =>
        LocaleKeys.settings_notifications_emptyInbox_title.tr(),
      MobileNotificationTabType.multiSelect =>
        LocaleKeys.settings_notifications_emptyInbox_title.tr(),
      MobileNotificationTabType.archive =>
        LocaleKeys.settings_notifications_emptyArchived_title.tr(),
      MobileNotificationTabType.unread =>
        LocaleKeys.settings_notifications_emptyUnread_title.tr(),
    };
    final desc = switch (type) {
      MobileNotificationTabType.inbox =>
        LocaleKeys.settings_notifications_emptyInbox_description.tr(),
      MobileNotificationTabType.multiSelect =>
        LocaleKeys.settings_notifications_emptyInbox_description.tr(),
      MobileNotificationTabType.archive =>
        LocaleKeys.settings_notifications_emptyArchived_description.tr(),
      MobileNotificationTabType.unread =>
        LocaleKeys.settings_notifications_emptyUnread_description.tr(),
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(FlowySvgs.m_empty_notification_xl),
        const VSpace(12.0),
        FlowyText(
          title,
          fontSize: 16.0,
          figmaLineHeight: 24.0,
          fontWeight: FontWeight.w500,
        ),
        const VSpace(4.0),
        Opacity(
          opacity: 0.45,
          child: FlowyText(
            desc,
            fontSize: 15.0,
            figmaLineHeight: 22.0,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
