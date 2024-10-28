import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/shared/colors.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_more_action.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/home_page_menu.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/publish_info_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
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
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: FlowyText(
        namespaceUrl,
        fontSize: 14.0,
        overflow: TextOverflow.ellipsis,
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
      return const _FreePlanUpgradeButton();
    }

    return const _HomePageButton();
  }
}

class _HomePageButton extends StatelessWidget {
  const _HomePageButton();

  @override
  Widget build(BuildContext context) {
    final homePageView = context.watch<SettingsSitesBloc>().state.homePageView;
    return Container(
      alignment: Alignment.centerLeft,
      child: AppFlowyPopover(
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
        child: homePageView == null
            ? _defaultHomePageButton(context)
            : PublishInfoViewItem(
                publishInfoView: homePageView,
              ),
      ),
    );
  }

  Widget _defaultHomePageButton(BuildContext context) {
    return const FlowyButton(
      useIntrinsicWidth: true,
      leftIcon: FlowySvg(
        FlowySvgs.search_s,
      ),
      leftIconSize: Size.square(14.0),
      text: FlowyText(
        'Select a page',
        figmaLineHeight: 18.0,
      ),
    );
  }
}

class _FreePlanUpgradeButton extends StatelessWidget {
  const _FreePlanUpgradeButton();

  @override
  Widget build(BuildContext context) {
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
            showToastNotification(
              context,
              message:
                  LocaleKeys.settings_sites_namespace_redirectToPayment.tr(),
              type: ToastificationType.info,
            );

            context.read<SettingsSitesBloc>().add(
                  const SettingsSitesEvent.upgradeSubscription(),
                );
          },
        ),
      ),
    );
  }
}
