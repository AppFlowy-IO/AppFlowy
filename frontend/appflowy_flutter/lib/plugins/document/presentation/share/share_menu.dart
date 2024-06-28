import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:appflowy/plugins/document/presentation/share/export_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'publish_tab.dart';

enum ShareMenuTab {
  share,
  publish,
  exportAs;

  static List<ShareMenuTab> supportedTabs = [
    // ShareMenuTab.share,
    ShareMenuTab.publish,
    ShareMenuTab.exportAs,
  ];

  String get i18n {
    switch (this) {
      case ShareMenuTab.share:
        return 'Share';
      case ShareMenuTab.publish:
        return LocaleKeys.shareAction_publish;
      case ShareMenuTab.exportAs:
        return 'Export as';
    }
  }
}

class ShareMenu extends StatefulWidget {
  const ShareMenu({super.key});

  @override
  State<ShareMenu> createState() => _ShareMenuState();
}

class _ShareMenuState extends State<ShareMenu>
    with SingleTickerProviderStateMixin {
  ShareMenuTab selectedTab = ShareMenuTab.publish;
  late final tabController = TabController(
    length: ShareMenuTab.supportedTabs.length,
    vsync: this,
    initialIndex: ShareMenuTab.supportedTabs.indexOf(selectedTab),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VSpace(10),
        Container(
          alignment: Alignment.centerLeft,
          height: 30,
          child: _buildTabBar(context),
        ),
        Divider(
          color: Theme.of(context).dividerColor,
          height: 1,
          thickness: 1,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: _buildTab(context),
        ),
        const VSpace(20),
      ],
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _buildTabBar(BuildContext context) {
    final children = [
      for (final tab in ShareMenuTab.supportedTabs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Segment(
            title: tab.i18n.tr(),
            isSelected: selectedTab == tab,
          ),
        ),
    ];
    return TabBar(
      indicatorSize: TabBarIndicatorSize.label,
      indicator: RoundUnderlineTabIndicator(
        width: 48.0,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 3,
        ),
        insets: const EdgeInsets.only(bottom: -2),
      ),
      isScrollable: true,
      controller: tabController,
      tabs: children,
      onTap: (index) {
        setState(() {
          selectedTab = ShareMenuTab.supportedTabs[index];
        });
      },
    );
  }

  Widget _buildTab(BuildContext context) {
    switch (selectedTab) {
      case ShareMenuTab.publish:
        return const PublishTab();
      case ShareMenuTab.exportAs:
        return const ExportTab();
      default:
        return const Center(
          child: FlowyText('🏡 under construction'),
        );
    }
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.title,
    required this.isSelected,
  });

  final String title;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? null : Theme.of(context).hintColor;
    return FlowyText(
      title,
      textAlign: TextAlign.center,
      color: textColor,
    );
  }
}
