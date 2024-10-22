import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:appflowy/plugins/shared/share/export_tab.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shortcuts/command_shortcuts.dart';

import 'publish_tab.dart';

enum ShareMenuTab {
  share,
  publish,
  exportAs;

  String get i18n {
    switch (this) {
      case ShareMenuTab.share:
        return LocaleKeys.shareAction_shareTab.tr();
      case ShareMenuTab.publish:
        return LocaleKeys.shareAction_publishTab.tr();
      case ShareMenuTab.exportAs:
        return LocaleKeys.shareAction_exportAsTab.tr();
    }
  }
}

class ShareMenu extends StatefulWidget {
  const ShareMenu({
    super.key,
    required this.tabs,
  });

  final List<ShareMenuTab> tabs;

  @override
  State<ShareMenu> createState() => _ShareMenuState();
}

class _ShareMenuState extends State<ShareMenu>
    with SingleTickerProviderStateMixin {
  late ShareMenuTab selectedTab = widget.tabs.first;
  late final tabController = TabController(
    length: widget.tabs.length,
    vsync: this,
    initialIndex: widget.tabs.indexOf(selectedTab),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return FocusableActionDetector(
      shortcuts: {
        customCopyToClipboardCommand.command: const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            // Call the existing 'Copy to clipboard' functionality
            // This is a placeholder implementation
            return null;
          },
        ),
      },
      child: Column(
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
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _buildTabBar(BuildContext context) {
    final children = [
      for (final tab in widget.tabs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Segment(
            tab: tab,
            isSelected: selectedTab == tab,
          ),
        ),
    ];
    return TabBar(
      indicatorSize: TabBarIndicatorSize.label,
      indicator: RoundUnderlineTabIndicator(
        width: 68.0,
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
          selectedTab = widget.tabs[index];
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
      case ShareMenuTab.share:
        return const ShareTab();
    }
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.tab,
    required this.isSelected,
  });

  final bool isSelected;
  final ShareMenuTab tab;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color? textColor = Theme.of(context).hintColor;
    if (isHovered) {
      textColor = const Color(0xFF00BCF0);
    } else if (widget.isSelected) {
      textColor = null;
    }

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: FlowyText(
        widget.tab.i18n,
        textAlign: TextAlign.center,
        color: textColor,
      ),
    );

    if (widget.tab == ShareMenuTab.publish) {
      final isPublished = context.watch<ShareBloc>().state.isPublished;
      // show checkmark icon if published
      if (isPublished) {
        child = Row(
          children: [
            const FlowySvg(
              FlowySvgs.published_checkmark_s,
              blendMode: null,
            ),
            const HSpace(6),
            child,
          ],
        );
      }
    }

    return child;
  }
}
