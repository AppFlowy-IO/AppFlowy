import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/flowy_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

class MobileNotificationTabBar extends StatefulWidget {
  const MobileNotificationTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  State<MobileNotificationTabBar> createState() =>
      _MobileNotificationTabBarState();
}

class _MobileNotificationTabBarState extends State<MobileNotificationTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: AFThemeExtension.of(context).calloutBGColor,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: borderSide,
          top: borderSide,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: widget.controller,
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
                  isSelected: widget.controller.index == 0,
                ),
                FlowyTabItem(
                  label: LocaleKeys.notificationHub_tabs_upcoming.tr(),
                  isSelected: widget.controller.index == 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
