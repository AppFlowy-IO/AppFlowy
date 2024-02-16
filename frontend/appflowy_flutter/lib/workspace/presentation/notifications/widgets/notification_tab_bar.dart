import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/flowy_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationTabBar extends StatelessWidget {
  const NotificationTabBar({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: tabController,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              isScrollable: true,
              tabs: [
                FlowyTabItem(
                  label: LocaleKeys.notificationHub_tabs_inbox.tr(),
                  isSelected: tabController.index == 0,
                ),
                FlowyTabItem(
                  label: LocaleKeys.notificationHub_tabs_upcoming.tr(),
                  isSelected: tabController.index == 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
