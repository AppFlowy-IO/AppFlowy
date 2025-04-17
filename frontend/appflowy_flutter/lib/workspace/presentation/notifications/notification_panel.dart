import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/notification_tab.dart';
import 'widgets/notification_tab_bar.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final ReminderBloc reminderBloc = getIt<ReminderBloc>();
  final PopoverController moreActionController = PopoverController();

  final tabs = [
    NotificationTabType.inbox,
    NotificationTabType.unread,
    NotificationTabType.archive,
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    moreActionController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingBloc = context.read<HomeSettingBloc>();
    return GestureDetector(
      onTap: () => settingBloc.add(HomeSettingEvent.collapseNotificationPanel()),
      child: Container(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(8, 0),
                  spreadRadius: 8,
                  color: Color(0x1F23290A),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTitle(
                  context: context,
                  onHide: () =>
                      settingBloc.add(HomeSettingEvent.collapseNotificationPanel()),
                ),
                const VSpace(12),
                NotificationTabBar(
                  tabController: tabController,
                  tabs: tabs,
                ),
                const VSpace(14),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: tabs.map((e) => NotificationTab(tabType: e)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTitle({
    required BuildContext context,
    required VoidCallback onHide,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 24,
        child: Row(
          children: [
            FlowyText.medium(
              LocaleKeys.notificationHub_title.tr(),
              fontSize: 16,
              figmaLineHeight: 24,
            ),
            Spacer(),
            FlowyIconButton(
              icon: FlowySvg(FlowySvgs.hide_menu_s),
              width: 24,
              richTooltipText: colappsedButtonTooltip(context),
              onPressed: onHide,
              iconPadding: const EdgeInsets.all(4),
            ),
            HSpace(8),
            buildMoreActionButton(context),
          ],
        ),
      );

  Widget buildMoreActionButton(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(240, 78)),
      offset: const Offset(-24, 24),
      margin: EdgeInsets.zero,
      controller: moreActionController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      popupBuilder: (_) => buildMoreActions(),
      child: FlowyIconButton(
        icon: FlowySvg(FlowySvgs.three_dots_s),
        width: 24,
        onPressed: () {
          keepEditorFocusNotifier.increase();
          moreActionController.show();
        },
        iconPadding: const EdgeInsets.all(4),
      ),
    );
  }

  Widget buildMoreActions() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 24,
            color: Color(0x0000001F),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 30,
            child: FlowyButton(
              text: FlowyText.regular(
                LocaleKeys.settings_notifications_settings_markAllAsRead.tr(),
              ),
              leftIcon: FlowySvg(FlowySvgs.m_notification_mark_as_read_s),
              onTap: () {
                showToastNotification(
                  message:
                      LocaleKeys.notificationHub_markAllAsReadSucceedToast.tr(),
                );
                context
                    .read<ReminderBloc>()
                    .add(const ReminderEvent.markAllRead());
                moreActionController.close();
              },
            ),
          ),
          VSpace(2),
          SizedBox(
            height: 30,
            child: FlowyButton(
              text: FlowyText.regular(
                LocaleKeys.settings_notifications_settings_archiveAll.tr(),
              ),
              leftIcon: FlowySvg(FlowySvgs.m_notification_archived_s),
              onTap: () {
                showToastNotification(
                  message: LocaleKeys
                      .notificationHub_markAllAsArchievedSucceedToast
                      .tr(),
                );
                context
                    .read<ReminderBloc>()
                    .add(const ReminderEvent.archiveAll());
                moreActionController.close();
              },
            ),
          ),
        ],
      ),
    );
  }

  TextSpan colappsedButtonTooltip(BuildContext context) {
    return TextSpan(
      children: [
        TextSpan(
          text: '${LocaleKeys.notificationHub_closeNotification.tr()}\n',
          style: context.tooltipTextStyle(),
        ),
        TextSpan(
          text: Platform.isMacOS ? '⌘+.' : 'Ctrl+\\',
          style: context
              .tooltipTextStyle()
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }

  void onAction(ReminderPB reminder, int? path, ViewPB? view) {
    reminderBloc.add(
      ReminderEvent.pressReminder(reminderId: reminder.id, path: path),
    );
  }

  void onReadChanged(ReminderPB reminder, bool isRead) {
    reminderBloc.add(
      ReminderEvent.update(ReminderUpdate(id: reminder.id, isRead: isRead)),
    );
  }
}
