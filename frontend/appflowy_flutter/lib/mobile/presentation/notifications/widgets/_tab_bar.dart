import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_tabbar/reorderable_tabbar.dart';

enum MobileNotificationTabType {
  inbox,
  unread,
  archive;

  String get tr {
    switch (this) {
      case MobileNotificationTabType.inbox:
        return 'Inbox';
      case MobileNotificationTabType.unread:
        return 'Unread';
      case MobileNotificationTabType.archive:
        return 'Archived';
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
      fontSize: 14.0,
      height: 20.0 / 14.0,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 8.0),
      child: ReorderableTabBar(
        controller: tabController,
        tabs: tabs.map((e) => Tab(text: e.tr)).toList(),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: Theme.of(context).primaryColor,
        isScrollable: true,
        labelStyle: labelStyle,
        labelColor: baseStyle?.color,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
        unselectedLabelStyle: unselectedLabelStyle,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        indicator: RoundUnderlineTabIndicator(
          width: 28.0,
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 3,
          ),
        ),
      ),
    );
  }
}
