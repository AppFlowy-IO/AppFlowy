import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
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
import 'package:appflowy/workspace/presentation/settings/widgets/web_url_hint_widget.dart';
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
@visibleForTesting
const kSelfHostedWebTextInputFieldKey =
    ValueKey('self_hosted_web_url_input_text_field');

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
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.role,
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
                          .currentWorkspace
                          ?.role,
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
    AFRolePB? currentWorkspaceMemberRole,
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
          currentWorkspaceMemberRole: currentWorkspaceMemberRole,
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
            key: ValueKey(workspaceId),
            userProfile: user,
            currentWorkspaceMemberRole: currentWorkspaceMemberRole,
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
  final cloudUrlTextController = TextEditingController();
  final webUrlTextController = TextEditingController();

  AuthenticatorType type = AuthenticatorType.appflowyCloud;

  @override
  void initState() {
    super.initState();

    _fetchUrls();
  }

  @override
  void dispose() {
    cloudUrlTextController.dispose();
    webUrlTextController.dispose();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelfHostUrlField(
          textFieldKey: kSelfHostedTextInputFieldKey,
          textController: cloudUrlTextController,
          title: LocaleKeys.settings_menu_cloudURL.tr(),
          hintText: LocaleKeys.settings_menu_cloudURLHint.tr(),
          onSave: (url) => _saveUrl(
            cloudUrl: url,
            webUrl: webUrlTextController.text,
            type: AuthenticatorType.appflowyCloudSelfHost,
          ),
        ),
        const VSpace(12.0),
        _SelfHostUrlField(
          textFieldKey: kSelfHostedWebTextInputFieldKey,
          textController: webUrlTextController,
          title: LocaleKeys.settings_menu_webURL.tr(),
          hintText: LocaleKeys.settings_menu_webURLHint.tr(),
          hintBuilder: (context) => const WebUrlHintWidget(),
          onSave: (url) => _saveUrl(
            cloudUrl: cloudUrlTextController.text,
            webUrl: url,
            type: AuthenticatorType.appflowyCloudSelfHost,
          ),
        ),
        const VSpace(12.0),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 78),
      child: OutlinedRoundedButton(
        text: LocaleKeys.button_save.tr(),
        onTap: () => _saveUrl(
          cloudUrl: cloudUrlTextController.text,
          webUrl: webUrlTextController.text,
          type: AuthenticatorType.appflowyCloudSelfHost,
        ),
      ),
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
      cloudUrlTextController.text = kAppflowyCloudUrl;
      webUrlTextController.text = ShareConstants.defaultBaseWebDomain;
      _saveUrl(
        cloudUrl: kAppflowyCloudUrl,
        webUrl: ShareConstants.defaultBaseWebDomain,
        type: type,
      );
    }
  }

  Future<void> _saveUrl({
    required String cloudUrl,
    required String webUrl,
    required AuthenticatorType type,
  }) async {
    if (cloudUrl.isEmpty || webUrl.isEmpty) {
      showToastNotification(
        context,
        message: LocaleKeys.settings_menu_pleaseInputValidURL.tr(),
        type: ToastificationType.error,
      );
      return;
    }

    final isValid = await _validateUrl(cloudUrl) && await _validateUrl(webUrl);

    if (mounted) {
      if (isValid) {
        showToastNotification(
          context,
          message: LocaleKeys.settings_menu_changeUrl.tr(args: [cloudUrl]),
        );

        Navigator.of(context).pop();

        await useBaseWebDomain(webUrl);
        await useAppFlowyBetaCloudWithURL(cloudUrl, type);

        await runAppFlowy();
      } else {
        showToastNotification(
          context,
          message: LocaleKeys.settings_menu_pleaseInputValidURL.tr(),
          type: ToastificationType.error,
        );
      }
    }
  }

  Future<bool> _validateUrl(String url) async {
    return await validateUrl(url).fold(
      (url) async {
        return true;
      },
      (err) {
        Log.error(err);
        return false;
      },
    );
  }

  Future<void> _fetchUrls() async {
    await Future.wait([
      getAppFlowyCloudUrl(),
      getAppFlowyShareDomain(),
    ]).then((values) {
      if (values.length != 2) {
        return;
      }

      cloudUrlTextController.text = values[0];
      webUrlTextController.text = values[1];

      if (kAppflowyCloudUrl != values[0]) {
        setState(() {
          type = AuthenticatorType.appflowyCloudSelfHost;
        });
      }
    });
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

class _SelfHostUrlField extends StatelessWidget {
  const _SelfHostUrlField({
    required this.textController,
    required this.title,
    required this.hintText,
    required this.onSave,
    this.textFieldKey,
    this.hintBuilder,
  });

  final TextEditingController textController;
  final String title;
  final String hintText;
  final ValueChanged<String> onSave;
  final Key? textFieldKey;
  final WidgetBuilder? hintBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHintWidget(context),
        const VSpace(6.0),
        SizedBox(
          height: 36,
          child: FlowyTextField(
            key: textFieldKey,
            controller: textController,
            autoFocus: false,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            hintText: hintText,
            onEditingComplete: () => onSave(textController.text),
          ),
        ),
      ],
    );
  }

  Widget _buildHintWidget(BuildContext context) {
    return Row(
      children: [
        FlowyText(
          title,
          overflow: TextOverflow.ellipsis,
        ),
        hintBuilder?.call(context) ?? const SizedBox.shrink(),
      ],
    );
  }
}
