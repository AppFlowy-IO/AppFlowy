import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    super.key,
    required this.changeSelectedPage,
    required this.currentPage,
    required this.userProfile,
    required this.isBillingEnabled,
  });

  final Function changeSelectedPage;
  final SettingsPage currentPage;
  final UserProfilePB userProfile;
  final bool isBillingEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    // Column > Expanded for full size no matter the content
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.backgroundColorScheme.secondary,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(8),
                bottomStart: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: 24,
                horizontal: theme.spacing.l,
              ),
              physics: const ClampingScrollPhysics(),
              child: SeparatedColumn(
                separatorBuilder: () => VSpace(theme.spacing.xs),
                children: [
                  SettingsMenuElement(
                    page: SettingsPage.account,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_accountPage_menuLabel.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_user_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.workspace,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_workspacePage_menuLabel.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_workspace_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  if (FeatureFlag.membersSettings.isOn &&
                      userProfile.workspaceAuthType == AuthTypePB.Server)
                    SettingsMenuElement(
                      page: SettingsPage.member,
                      selectedPage: currentPage,
                      label: LocaleKeys.settings_appearance_members_label.tr(),
                      icon: const FlowySvg(FlowySvgs.settings_page_users_m),
                      changeSelectedPage: changeSelectedPage,
                    ),
                  SettingsMenuElement(
                    page: SettingsPage.manageData,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_manageDataPage_menuLabel.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_database_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.notifications,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_menu_notifications.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_bell_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.cloud,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_menu_cloudSettings.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_cloud_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.shortcuts,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_shortcutsPage_menuLabel.tr(),
                    icon: const FlowySvg(FlowySvgs.settings_page_keyboard_m),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.ai,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_aiPage_menuLabel.tr(),
                    icon: const FlowySvg(
                      FlowySvgs.settings_page_ai_m,
                    ),
                    changeSelectedPage: changeSelectedPage,
                  ),
                  if (userProfile.workspaceAuthType == AuthTypePB.Server)
                    SettingsMenuElement(
                      page: SettingsPage.sites,
                      selectedPage: currentPage,
                      label: LocaleKeys.settings_sites_title.tr(),
                      icon: const FlowySvg(FlowySvgs.settings_page_earth_m),
                      changeSelectedPage: changeSelectedPage,
                    ),
                  if (FeatureFlag.planBilling.isOn && isBillingEnabled) ...[
                    SettingsMenuElement(
                      page: SettingsPage.plan,
                      selectedPage: currentPage,
                      label: LocaleKeys.settings_planPage_menuLabel.tr(),
                      icon: const FlowySvg(FlowySvgs.settings_page_plan_m),
                      changeSelectedPage: changeSelectedPage,
                    ),
                    SettingsMenuElement(
                      page: SettingsPage.billing,
                      selectedPage: currentPage,
                      label: LocaleKeys.settings_billingPage_menuLabel.tr(),
                      icon:
                          const FlowySvg(FlowySvgs.settings_page_credit_card_m),
                      changeSelectedPage: changeSelectedPage,
                    ),
                  ],
                  if (kDebugMode)
                    SettingsMenuElement(
                      // no need to translate this page
                      page: SettingsPage.featureFlags,
                      selectedPage: currentPage,
                      label: 'Feature Flags',
                      icon: const Icon(
                        Icons.flag,
                        size: 20,
                      ),
                      changeSelectedPage: changeSelectedPage,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SimpleSettingsMenu extends StatelessWidget {
  const SimpleSettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8) +
                const EdgeInsets.only(left: 8, right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              // Right padding is added to make the scrollbar centered
              // in the space between the menu and the content
              padding: const EdgeInsets.only(right: 4) +
                  const EdgeInsets.symmetric(vertical: 16),
              physics: const ClampingScrollPhysics(),
              child: SeparatedColumn(
                separatorBuilder: () => const VSpace(16),
                children: [
                  SettingsMenuElement(
                    page: SettingsPage.cloud,
                    selectedPage: SettingsPage.cloud,
                    label: LocaleKeys.settings_menu_cloudSettings.tr(),
                    icon: const Icon(Icons.sync),
                    changeSelectedPage: () {},
                  ),
                  if (kDebugMode)
                    SettingsMenuElement(
                      // no need to translate this page
                      page: SettingsPage.featureFlags,
                      selectedPage: SettingsPage.cloud,
                      label: 'Feature Flags',
                      icon: const Icon(Icons.flag),
                      changeSelectedPage: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
