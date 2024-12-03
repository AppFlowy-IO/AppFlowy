import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/shared/colors.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_more_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/home_page_menu.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/publish_info_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DomainItem extends StatelessWidget {
  const DomainItem({
    super.key,
    required this.namespace,
    required this.homepage,
  });

  final String namespace;
  final String homepage;

  @override
  Widget build(BuildContext context) {
    final namespaceUrl = ShareConstants.buildNamespaceUrl(
      nameSpace: namespace,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Namespace
        Expanded(
          child: _buildNamespace(context, namespaceUrl),
        ),
        // Homepage
        Expanded(
          child: _buildHomepage(context),
        ),
        // ... button
        DomainMoreAction(namespace: namespace),
      ],
    );
  }

  Widget _buildNamespace(BuildContext context, String namespaceUrl) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(right: 12.0),
      child: FlowyTooltip(
        message: '${LocaleKeys.shareAction_visitSite.tr()}\n$namespaceUrl',
        child: FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText(
            namespaceUrl,
            fontSize: 14.0,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            final namespaceUrl = ShareConstants.buildNamespaceUrl(
              nameSpace: namespace,
              withHttps: true,
            );
            afLaunchUrlString(namespaceUrl);
          },
        ),
      ),
    );
  }

  Widget _buildHomepage(BuildContext context) {
    final plan = context.read<SettingsSitesBloc>().state.subscriptionInfo?.plan;

    if (plan == null) {
      return const SizedBox.shrink();
    }

    final isFreePlan = plan == WorkspacePlanPB.FreePlan;
    if (isFreePlan) {
      return const Padding(
        padding: EdgeInsets.only(
          left: SettingsPageSitesConstants.alignPadding,
        ),
        child: _FreePlanUpgradeButton(),
      );
    }

    return const _HomePageButton();
  }
}

class _HomePageButton extends StatelessWidget {
  const _HomePageButton();

  @override
  Widget build(BuildContext context) {
    final settingsSitesState = context.watch<SettingsSitesBloc>().state;
    if (settingsSitesState.isLoading) {
      return const SizedBox.shrink();
    }

    final isOwner = context
            .watch<UserWorkspaceBloc>()
            .state
            .currentWorkspaceMember
            ?.role
            .isOwner ??
        false;

    final homePageView = settingsSitesState.homePageView;
    Widget child = homePageView == null
        ? _defaultHomePageButton(context)
        : PublishInfoViewItem(
            publishInfoView: homePageView,
            margin: isOwner ? null : EdgeInsets.zero,
          );

    if (isOwner) {
      child = _buildHomePageButtonForOwner(
        context,
        homePageView: homePageView,
        child: child,
      );
    } else {
      child = _buildHomePageButtonForNonOwner(context, child);
    }

    return Container(
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  Widget _buildHomePageButtonForOwner(
    BuildContext context, {
    required PublishInfoViewPB? homePageView,
    required Widget child,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFlowyPopover(
          direction: PopoverDirection.bottomWithCenterAligned,
          constraints: const BoxConstraints(
            maxWidth: 260,
            maxHeight: 345,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 12.0,
          ),
          popupBuilder: (_) {
            final bloc = context.read<SettingsSitesBloc>();
            return BlocProvider.value(
              value: bloc,
              child: SelectHomePageMenu(
                userProfile: bloc.user,
                workspaceId: bloc.workspaceId,
                onSelected: (view) {},
              ),
            );
          },
          child: child,
        ),
        if (homePageView != null)
          FlowyTooltip(
            message: LocaleKeys.settings_sites_clearHomePage.tr(),
            child: FlowyButton(
              margin: const EdgeInsets.all(4.0),
              useIntrinsicWidth: true,
              onTap: () {
                context.read<SettingsSitesBloc>().add(
                      const SettingsSitesEvent.removeHomePage(),
                    );
              },
              text: const FlowySvg(
                FlowySvgs.close_m,
                size: Size.square(19.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHomePageButtonForNonOwner(
    BuildContext context,
    Widget child,
  ) {
    return FlowyTooltip(
      message: LocaleKeys
          .settings_sites_namespace_onlyWorkspaceOwnerCanSetHomePage
          .tr(),
      child: IgnorePointer(
        child: child,
      ),
    );
  }

  Widget _defaultHomePageButton(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      leftIcon: const FlowySvg(
        FlowySvgs.search_s,
      ),
      leftIconSize: const Size.square(14.0),
      text: FlowyText(
        LocaleKeys.settings_sites_selectHomePage.tr(),
        figmaLineHeight: 18.0,
      ),
    );
  }
}

class _FreePlanUpgradeButton extends StatelessWidget {
  const _FreePlanUpgradeButton();

  @override
  Widget build(BuildContext context) {
    final isOwner = context
            .watch<UserWorkspaceBloc>()
            .state
            .currentWorkspaceMember
            ?.role
            .isOwner ??
        false;
    return Container(
      alignment: Alignment.centerLeft,
      child: FlowyTooltip(
        message: LocaleKeys.settings_sites_namespace_upgradeToPro.tr(),
        child: PrimaryRoundedButton(
          text: 'Pro ↗',
          fontSize: 12.0,
          figmaLineHeight: 16.0,
          fontWeight: FontWeight.w600,
          radius: 8.0,
          textColor: context.proPrimaryColor,
          backgroundColor: context.proSecondaryColor,
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 6.0,
          ),
          hoverColor: context.proSecondaryColor.withOpacity(0.9),
          onTap: () {
            if (isOwner) {
              showToastNotification(
                context,
                message:
                    LocaleKeys.settings_sites_namespace_redirectToPayment.tr(),
                type: ToastificationType.info,
              );

              context.read<SettingsSitesBloc>().add(
                    const SettingsSitesEvent.upgradeSubscription(),
                  );
            } else {
              showToastNotification(
                context,
                message: LocaleKeys
                    .settings_sites_namespace_pleaseAskOwnerToSetHomePage
                    .tr(),
                type: ToastificationType.info,
              );
            }
          },
        ),
      ),
    );
  }
}
