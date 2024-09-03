import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/workspace/invite_members_screen.dart';
import 'package:appflowy/shared/popup_menu/appflowy_popup_menu.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart'
    hide PopupMenuButton, PopupMenuDivider, PopupMenuItem, PopupMenuEntry;
import 'package:go_router/go_router.dart';

enum _MobileSettingsPopupMenuItem {
  settings,
  members,
  trash,
  help,
}

class HomePageSettingsPopupMenu extends StatelessWidget {
  const HomePageSettingsPopupMenu({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {

    return PopupMenuButton<_MobileSettingsPopupMenuItem>(
      offset: const Offset(0, 36),
      padding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
      shadowColor: const Color(0x68000000),
      elevation: 10,
      color: context.popupMenuBackgroundColor,
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<_MobileSettingsPopupMenuItem>>[
        _buildItem(
          value: _MobileSettingsPopupMenuItem.settings,
          svg: FlowySvgs.m_notification_settings_s,
          text: LocaleKeys.settings_popupMenuItem_settings.tr(),
        ),
        // only show the member items in cloud mode
        if (userProfile.authenticator == AuthenticatorPB.AppFlowyCloud) ...[
          const PopupMenuDivider(height: 0.5),
          _buildItem(
            value: _MobileSettingsPopupMenuItem.members,
            svg: FlowySvgs.m_settings_member_s,
            text: LocaleKeys.settings_popupMenuItem_members.tr(),
          ),
        ],
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: _MobileSettingsPopupMenuItem.trash,
          svg: FlowySvgs.trash_s,
          text: LocaleKeys.settings_popupMenuItem_trash.tr(),
        ),
        const PopupMenuDivider(height: 0.5),
        _buildItem(
          value: _MobileSettingsPopupMenuItem.help,
          svg: FlowySvgs.message_support_s,
          text: LocaleKeys.settings_popupMenuItem_helpAndSupport.tr(),
        ),
      ],
      onSelected: (_MobileSettingsPopupMenuItem value) {
        switch (value) {
          case _MobileSettingsPopupMenuItem.members:
            _openMembersPage(context);
            break;
          case _MobileSettingsPopupMenuItem.trash:
            _openTrashPage(context);
            break;
          case _MobileSettingsPopupMenuItem.settings:
            _openSettingsPage(context);
            break;
          case _MobileSettingsPopupMenuItem.help:
            _openHelpPage(context);
            break;
        }
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: FlowySvg(
          FlowySvgs.m_settings_more_s,
        ),
      ),
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

  void _openMembersPage(BuildContext context) {
    context.push(InviteMembersScreen.routeName);
  }

  void _openTrashPage(BuildContext context) {
    context.push(MobileHomeTrashPage.routeName);
  }

  void _openHelpPage(BuildContext context) {
    afLaunchUrlString('https://discord.com/invite/9Q2xaN37tV');
  }

  void _openSettingsPage(BuildContext context) {
    context.push(MobileHomeSettingPage.routeName);
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
          FlowySvg(svg, size: const Size.square(20)),
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
