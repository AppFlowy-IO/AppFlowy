import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_tabbar/reorderable_tabbar.dart';

enum MobileNotificationTabType {
  inbox,
  unread,
  archive;

  String get tr {
    switch (this) {
      case MobileNotificationTabType.inbox:
        return LocaleKeys.settings_notifications_tabs_inbox.tr();
      case MobileNotificationTabType.unread:
        return LocaleKeys.settings_notifications_tabs_unread.tr();
      case MobileNotificationTabType.archive:
        return LocaleKeys.settings_notifications_tabs_archived.tr();
    }
  }

  List<NotificationPaneActionType> get actions {
    switch (this) {
      case MobileNotificationTabType.inbox:
        return [
          NotificationPaneActionType.more,
          NotificationPaneActionType.markAsRead,
        ];
      case MobileNotificationTabType.unread:
      case MobileNotificationTabType.archive:
        return [];
    }
  }
}

class MobileNotificationTabBar extends StatelessWidget {
  const MobileNotificationTabBar({
    super.key,
    this.height = 38.0,
    required this.tabController,
    required this.tabs,
  });

  final double height;
  final List<MobileNotificationTabType> tabs;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium;
    final labelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
      height: 22.0 / 16.0,
    );
    final unselectedLabelStyle = baseStyle?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 15.0,
      height: 22.0 / 15.0,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 8.0),
      child: ReorderableTabBar(
        controller: tabController,
        tabs: tabs.map((e) => Tab(text: e.tr)).toList(),
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        labelStyle: labelStyle,
        labelColor: baseStyle?.color,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        unselectedLabelStyle: unselectedLabelStyle,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: const RoundUnderlineTabIndicator(
          width: 28.0,
          borderSide: BorderSide(
            color: Color(0xFF00C8FF),
            width: 3,
          ),
        ),
      ),
    );
  }
}
