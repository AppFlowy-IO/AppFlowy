import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'publish_tab.dart';

enum ShareMenuTab {
  share,
  publish,
  exportAs;

  static List<ShareMenuTab> supportedTabs = [
    ShareMenuTab.share,
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

class _ShareMenuState extends State<ShareMenu> {
  ShareMenuTab selectedTab = ShareMenuTab.publish;

  @override
  Widget build(BuildContext context) {
    final children = {
      for (final tab in ShareMenuTab.supportedTabs)
        tab: _Segment(
          title: tab.i18n.tr(),
          isSelected: selectedTab == tab,
        ),
    };
    final color = Theme.of(context).isLightMode
        ? const Color(0xFFEEF0F3)
        : Colors.black.withOpacity(0.3);
    final thumbColor = Theme.of(context).isLightMode
        ? Colors.white
        : Theme.of(context).colorScheme.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          child: CustomSlidingSegmentedControl<ShareMenuTab>(
            initialValue: selectedTab,
            curve: Curves.linear,
            padding: 0,
            fixedWidth: 128,
            innerPadding: const EdgeInsets.all(3.0),
            children: children,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            thumbDecoration: BoxDecoration(
              color: thumbColor,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x141F2225),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            onValueChanged: (v) {
              setState(() {
                selectedTab = v;
              });
            },
          ),
        ),
        _buildTab(context),
      ],
    );
  }

  Widget _buildTab(BuildContext context) {
    switch (selectedTab) {
      case ShareMenuTab.publish:
        return const PublishTab();

      default:
        return const Center(
          child: FlowyText('coming soon'),
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
