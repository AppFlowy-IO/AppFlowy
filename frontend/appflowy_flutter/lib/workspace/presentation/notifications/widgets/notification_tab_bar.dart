import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class NotificationTabBar extends StatelessWidget {
  final TabController tabController;

  const NotificationTabBar({
    super.key,
    required this.tabController,
  });

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
                _FlowyTab(
                  label: LocaleKeys.notificationHub_tabs_inbox.tr(),
                  isSelected: tabController.index == 0,
                ),
                _FlowyTab(
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

class _FlowyTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FlowyTab({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FlowyText.regular(
          label,
          color: isSelected ? Theme.of(context).colorScheme.tertiary : null,
        ),
      ),
    );
  }
}
