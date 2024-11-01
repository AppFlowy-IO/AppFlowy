import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/appflowy_cache_manager.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/share_log_files.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appflowy_cloud_urls_bloc.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/settings_ai_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_account_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_billing_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_manage_data_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_shortcuts_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_workspace_view.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_view.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/feature_flag_page.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_page.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_notifications_view.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/setting_cloud.dart';

@visibleForTesting
const kSelfHostedTextInputFieldKey =
    ValueKey('self_hosted_url_input_text_field');

class SettingsDialog extends StatelessWidget {
  SettingsDialog(
    this.user, {
    required this.dismissDialog,
    required this.didLogout,
    required this.restartApp,
    this.initPage,
  }) : super(key: ValueKey(user.id));

  final UserProfilePB user;
  final SettingsPage? initPage;
  final VoidCallback dismissDialog;
  final VoidCallback didLogout;
  final VoidCallback restartApp;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.6;
    return BlocProvider<SettingsDialogBloc>(
      create: (context) => SettingsDialogBloc(
        user,
        context.read<UserWorkspaceBloc>().state.currentWorkspaceMember,
        initPage: initPage,
      )..add(const SettingsDialogEvent.initial()),
      child: BlocBuilder<SettingsDialogBloc, SettingsDialogState>(
        builder: (context, state) => FlowyDialog(
          width: width,
          constraints: const BoxConstraints(minWidth: 564),
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: SettingsMenu(
                      userProfile: user,
                      changeSelectedPage: (index) => context
                          .read<SettingsDialogBloc>()
                          .add(SettingsDialogEvent.setSelectedPage(index)),
                      currentPage:
                          context.read<SettingsDialogBloc>().state.page,
                      isBillingEnabled: state.isBillingEnabled,
                      member: context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspaceMember,
                    ),
                  ),
                  Expanded(
                    child: getSettingsView(
                      context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspace!
                          .workspaceId,
                      context.read<SettingsDialogBloc>().state.page,
                      context.read<SettingsDialogBloc>().state.userProfile,
                      context
                          .read<UserWorkspaceBloc>()
                          .state
                          .currentWorkspaceMember,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getSettingsView(
    String workspaceId,
    SettingsPage page,
    UserProfilePB user,
    WorkspaceMemberPB? member,
  ) {
    switch (page) {
      case SettingsPage.account:
        return SettingsAccountView(
          userProfile: user,
          didLogout: didLogout,
          didLogin: dismissDialog,
        );
      case SettingsPage.workspace:
        return SettingsWorkspaceView(
          userProfile: user,
          workspaceMember: member,
        );
      case SettingsPage.manageData:
        return SettingsManageDataView(userProfile: user);
      case SettingsPage.notifications:
        return const SettingsNotificationsView();
      case SettingsPage.cloud:
        return SettingCloud(restartAppFlowy: () => restartApp());
      case SettingsPage.shortcuts:
        return const SettingsShortcutsView();
      case SettingsPage.ai:
        if (user.authenticator == AuthenticatorPB.AppFlowyCloud) {
          return SettingsAIView(
            userProfile: user,
            member: member,
            workspaceId: workspaceId,
          );
        } else {
          return const AIFeatureOnlySupportedWhenUsingAppFlowyCloud();
        }
      case SettingsPage.member:
        return WorkspaceMembersPage(
          userProfile: user,
          workspaceId: workspaceId,
        );
      case SettingsPage.plan:
        return SettingsPlanView(
          workspaceId: workspaceId,
          user: user,
        );
      case SettingsPage.billing:
        return SettingsBillingView(
          workspaceId: workspaceId,
          user: user,
        );
      case SettingsPage.sites:
        return SettingsSitesPage(
          workspaceId: workspaceId,
          user: user,
        );
      case SettingsPage.featureFlags:
        return const FeatureFlagsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

class SimpleSettingsDialog extends StatefulWidget {
  const SimpleSettingsDialog({super.key});

  @override
  State<SimpleSettingsDialog> createState() => _SimpleSettingsDialogState();
}

class _SimpleSettingsDialogState extends State<SimpleSettingsDialog> {
  SettingsPage page = SettingsPage.cloud;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppearanceSettingsCubit>().state;

    return FlowyDialog(
      width: MediaQuery.of(context).size.width * 0.7,
      constraints: const BoxConstraints(maxWidth: 784, minWidth: 564),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
              FlowyText(
                LocaleKeys.signIn_settings.tr(),
                fontSize: 36.0,
                fontWeight: FontWeight.w600,
              ),
              const VSpace(18.0),

              // language
              _LanguageSettings(key: ValueKey('language${settings.hashCode}')),
              const VSpace(22.0),

              // self-host cloud
              _SelfHostSettings(key: ValueKey('selfhost${settings.hashCode}')),
              const VSpace(22.0),

              // support
              _SupportSettings(key: ValueKey('support${settings.hashCode}')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSettings extends StatelessWidget {
  const _LanguageSettings({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCategory(
      title: LocaleKeys.settings_workspacePage_language_title.tr(),
      children: const [LanguageDropdown()],
    );
  }
}

class _SelfHostSettings extends StatefulWidget {
  const _SelfHostSettings({
    super.key,
  });

  @override
  State<_SelfHostSettings> createState() => _SelfHostSettingsState();
}

class _SelfHostSettingsState extends State<_SelfHostSettings> {
  final textController = TextEditingController();
  AuthenticatorType type = AuthenticatorType.appflowyCloud;

  @override
  void initState() {
    super.initState();

    getAppFlowyCloudUrl().then((url) {
      textController.text = url;
      if (kAppflowyCloudUrl != url) {
        setState(() {
          type = AuthenticatorType.appflowyCloudSelfHost;
        });
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCategory(
      title: LocaleKeys.settings_menu_cloudAppFlowy.tr(),
      children: [
        Flexible(
          child: SettingsServerDropdownMenu(
            selectedServer: type,
            onSelected: _onSelected,
          ),
        ),
        if (type == AuthenticatorType.appflowyCloudSelfHost) _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: FlowyTextField(
              key: kSelfHostedTextInputFieldKey,
              controller: textController,
              autoFocus: false,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              hintText: kAppflowyCloudUrl,
              onEditingComplete: () => _saveUrl(
                url: textController.text,
                type: AuthenticatorType.appflowyCloudSelfHost,
              ),
            ),
          ),
        ),
        const HSpace(12.0),
        Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 78),
          child: OutlinedRoundedButton(
            text: LocaleKeys.button_save.tr(),
            onTap: () => _saveUrl(
              url: textController.text,
              type: AuthenticatorType.appflowyCloudSelfHost,
            ),
          ),
        ),
      ],
    );
  }

  void _onSelected(AuthenticatorType type) {
    if (type == this.type) {
      return;
    }

    Log.info('Switching server type to $type');

    setState(() {
      this.type = type;
    });

    if (type == AuthenticatorType.appflowyCloud) {
      textController.text = kAppflowyCloudUrl;
      _saveUrl(
        url: textController.text,
        type: type,
      );
    }
  }

  void _saveUrl({
    required String url,
    required AuthenticatorType type,
  }) {
    if (url.isEmpty) {
      showToastNotification(
        context,
        message: LocaleKeys.settings_menu_pleaseInputValidURL.tr(),
        type: ToastificationType.error,
      );
      return;
    }

    validateUrl(url).fold(
      (url) async {
        showToastNotification(
          context,
          message: LocaleKeys.settings_menu_changeUrl.tr(args: [url]),
        );

        Navigator.of(context).pop();
        await useAppFlowyBetaCloudWithURL(url, type);
        await runAppFlowy();
      },
      (err) {
        showToastNotification(
          context,
          message: LocaleKeys.settings_menu_pleaseInputValidURL.tr(),
          type: ToastificationType.error,
        );
        Log.error(err);
      },
    );
  }
}

@visibleForTesting
extension SettingsServerDropdownMenuExtension on AuthenticatorType {
  String get label {
    switch (this) {
      case AuthenticatorType.appflowyCloud:
        return LocaleKeys.settings_menu_cloudAppFlowy.tr();
      case AuthenticatorType.appflowyCloudSelfHost:
        return LocaleKeys.settings_menu_cloudAppFlowySelfHost.tr();
      default:
        throw Exception('Unsupported server type: $this');
    }
  }
}

@visibleForTesting
class SettingsServerDropdownMenu extends StatelessWidget {
  const SettingsServerDropdownMenu({
    super.key,
    required this.selectedServer,
    required this.onSelected,
  });

  final AuthenticatorType selectedServer;
  final void Function(AuthenticatorType type) onSelected;

  // in the settings page from sign in page, we only support appflowy cloud and self-hosted
  static final supportedServers = [
    AuthenticatorType.appflowyCloud,
    AuthenticatorType.appflowyCloudSelfHost,
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsDropdown<AuthenticatorType>(
      expandWidth: false,
      onChanged: onSelected,
      selectedOption: selectedServer,
      options: supportedServers
          .map(
            (serverType) => buildDropdownMenuEntry<AuthenticatorType>(
              context,
              selectedValue: selectedServer,
              value: serverType,
              label: serverType.label,
            ),
          )
          .toList(),
    );
  }
}

class _SupportSettings extends StatelessWidget {
  const _SupportSettings({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCategory(
      title: LocaleKeys.settings_mobile_support.tr(),
      children: [
        // export logs
        Row(
          children: [
            FlowyText(
              LocaleKeys.workspace_errorActions_exportLogFiles.tr(),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 78),
              child: OutlinedRoundedButton(
                text: LocaleKeys.settings_files_export.tr(),
                onTap: () {
                  shareLogFiles(context);
                },
              ),
            ),
          ],
        ),
        // clear cache
        Row(
          children: [
            FlowyText(
              LocaleKeys.settings_files_clearCache.tr(),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 78),
              child: OutlinedRoundedButton(
                text: LocaleKeys.button_clear.tr(),
                onTap: () async {
                  await getIt<FlowyCacheManager>().clearAllCache();
                  if (context.mounted) {
                    showToastNotification(
                      context,
                      message: LocaleKeys
                          .settings_manageDataPage_cache_dialog_successHint
                          .tr(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
