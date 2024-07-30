import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum _NotificationSettingsPopupMenuItem {
  settings,
  markAllAsRead,
  archiveAll,
}

class NotificationSettingsPopupMenu extends StatelessWidget {
  const NotificationSettingsPopupMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_NotificationSettingsPopupMenuItem>(
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
      // todo: replace it with shadows
      shadowColor: const Color(0x68000000),
      elevation: 10,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: FlowySvg(
          FlowySvgs.m_settings_more_s,
          blendMode: null,
        ),
      ),
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<_NotificationSettingsPopupMenuItem>>[
        _buildItem(
          value: _NotificationSettingsPopupMenuItem.settings,
          svg: FlowySvgs.m_notification_settings_s,
          text: LocaleKeys.settings_notifications_settings_settings.tr(),
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: _NotificationSettingsPopupMenuItem.markAllAsRead,
          svg: FlowySvgs.m_notification_mark_as_read_s,
          text: LocaleKeys.settings_notifications_settings_markAllAsRead.tr(),
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: _NotificationSettingsPopupMenuItem.archiveAll,
          svg: FlowySvgs.m_notification_archived_s,
          text: LocaleKeys.settings_notifications_settings_archiveAll.tr(),
        ),
      ],
      onSelected: (_NotificationSettingsPopupMenuItem value) {
        switch (value) {
          case _NotificationSettingsPopupMenuItem.markAllAsRead:
            _onMarkAllAsRead(context);
            break;
          case _NotificationSettingsPopupMenuItem.archiveAll:
            _onArchiveAll(context);
            break;
          case _NotificationSettingsPopupMenuItem.settings:
            context.push(MobileHomeSettingPage.routeName);
            break;
        }
      },
    );
  }

  PopupMenuItem<T> _buildItem<T>({
    required T value,
    required FlowySvgData svg,
    required String text,
  }) {
    return PopupMenuItem<T>(
      value: value,
      padding: EdgeInsets.zero,
      child: _PopupButton(
        svg: svg,
        text: text,
      ),
    );
  }

  void _onMarkAllAsRead(BuildContext context) {
    context.read<ReminderBloc>().add(const ReminderEvent.markAllRead());
  }

  void _onArchiveAll(BuildContext context) {
    context.read<ReminderBloc>().add(const ReminderEvent.archiveAll());
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.svg,
    required this.text,
  });

  final FlowySvgData svg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FlowySvg(svg),
          const HSpace(12),
          FlowyText.regular(
            text,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}
