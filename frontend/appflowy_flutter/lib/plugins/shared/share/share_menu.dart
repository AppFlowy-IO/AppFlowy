import 'package:appflowy/features/share_tab/presentation/share_tab.dart'
    as share_section;
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/_round_underline_tab_indicator.dart';
import 'package:appflowy/plugins/shared/share/export_tab.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/plugins/shared/share/share_tab.dart' as share_plugin;
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    required this.viewName,
    required this.onClose,
  });

  final List<ShareMenuTab> tabs;
  final String viewName;
  final VoidCallback onClose;

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

    final theme = AppFlowyTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VSpace(theme.spacing.xs),
        Container(
          alignment: Alignment.centerLeft,
          height: 28,
          child: _buildTabBar(context),
        ),
        const AFDivider(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
          child: _buildTab(context),
        ),
      ],
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final children = [
      for (final tab in widget.tabs)
        Padding(
          padding: EdgeInsets.only(bottom: theme.spacing.s),
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
        insets: const EdgeInsets.only(bottom: -1),
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
        return PublishTab(
          viewName: widget.viewName,
        );
      case ShareMenuTab.exportAs:
        return const ExportTab();
      case ShareMenuTab.share:
        if (FeatureFlag.sharedSection.isOn) {
          final workspace =
              context.read<UserWorkspaceBloc>().state.currentWorkspace;
          final workspaceId = workspace?.workspaceId ??
              context.read<ShareBloc>().state.workspaceId;
          final pageId = context.read<ShareBloc>().state.viewId;
          final isInProPlan = context
                  .read<UserWorkspaceBloc>()
                  .state
                  .workspaceSubscriptionInfo
                  ?.plan ==
              WorkspacePlanPB.ProPlan;

          return share_section.ShareTab(
            workspaceId: workspaceId,
            pageId: pageId,
            workspaceName: workspace?.name ?? '',
            workspaceIcon: workspace?.icon ?? '',
            isInProPlan: isInProPlan,
            onUpgradeToPro: () {
              widget.onClose();

              _showUpgradeToProDialog(context);
            },
          );
        }

        return const share_plugin.ShareTab();
    }
  }

  void _showUpgradeToProDialog(BuildContext context) {
    final state = context.read<UserWorkspaceBloc>().state;
    final workspace = state.currentWorkspace;
    if (workspace == null) {
      Log.error('workspace is null');
      return;
    }

    final workspaceId = workspace.workspaceId;
    final subscriptionInfo = state.workspaceSubscriptionInfo;
    final userProfile = state.userProfile;
    if (subscriptionInfo == null) {
      Log.error('subscriptionInfo is null');
      return;
    }

    final role = workspace.role;
    final title = switch (role) {
      AFRolePB.Owner =>
        LocaleKeys.shareTab_upgradeToInviteGuest_title_owner.tr(),
      AFRolePB.Member =>
        LocaleKeys.shareTab_upgradeToInviteGuest_title_member.tr(),
      AFRolePB.Guest ||
      _ =>
        LocaleKeys.shareTab_upgradeToInviteGuest_title_guest.tr(),
    };
    final description = switch (role) {
      AFRolePB.Owner =>
        LocaleKeys.shareTab_upgradeToInviteGuest_description_owner.tr(),
      AFRolePB.Member =>
        LocaleKeys.shareTab_upgradeToInviteGuest_description_member.tr(),
      AFRolePB.Guest ||
      _ =>
        LocaleKeys.shareTab_upgradeToInviteGuest_description_guest.tr(),
    };
    final style = switch (role) {
      AFRolePB.Owner => ConfirmPopupStyle.cancelAndOk,
      AFRolePB.Member || AFRolePB.Guest || _ => ConfirmPopupStyle.onlyOk,
    };
    final confirmLabel = switch (role) {
      AFRolePB.Owner => LocaleKeys.shareTab_upgrade.tr(),
      AFRolePB.Member || AFRolePB.Guest || _ => LocaleKeys.button_ok.tr(),
    };

    if (role == AFRolePB.Owner) {
      showDialog(
        context: context,
        builder: (_) => BlocProvider<SettingsPlanBloc>(
          create: (_) => SettingsPlanBloc(
            workspaceId: workspaceId,
            userId: userProfile.id,
          )..add(const SettingsPlanEvent.started()),
          child: SettingsPlanComparisonDialog(
            workspaceId: workspaceId,
            subscriptionInfo: subscriptionInfo,
          ),
        ),
      );
    } else {
      showConfirmDialog(
        context: Navigator.of(context, rootNavigator: true).context,
        title: title,
        description: description,
        style: style,
        confirmLabel: confirmLabel,
        confirmButtonColor: Theme.of(context).colorScheme.primary,
        onConfirm: (context) {
          // fixme: show the upgrade to pro dialog
        },
      );
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
    final theme = AppFlowyTheme.of(context);

    final textColor = widget.isSelected || isHovered
        ? theme.textColorScheme.primary
        : theme.textColorScheme.secondary;

    Widget child = MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Text(
        widget.tab.i18n,
        textAlign: TextAlign.center,
        style: theme.textStyle.body.enhanced(
          color: textColor,
        ),
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
