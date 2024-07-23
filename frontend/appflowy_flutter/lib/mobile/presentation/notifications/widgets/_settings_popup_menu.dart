import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPopupMenu extends StatelessWidget {
  const NotificationSettingsPopupMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
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
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildItem(
          value: 'settings',
          svg: FlowySvgs.m_notification_settings_s,
          text: 'Settings',
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: 'mark_read',
          svg: FlowySvgs.m_notification_mark_as_read_s,
          text: 'Mark all as read',
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: 'archive',
          svg: FlowySvgs.m_notification_archived_s,
          text: 'Archive all',
        ),
      ],
      onSelected: (String value) {
        // Handle menu item selection
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
