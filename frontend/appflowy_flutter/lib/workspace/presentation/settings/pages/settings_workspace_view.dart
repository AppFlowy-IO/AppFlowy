import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/workspace/workspace_settings_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_actionable_input.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_event.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsWorkspaceView extends StatefulWidget {
  const SettingsWorkspaceView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SettingsWorkspaceView> createState() => _SettingsWorkspaceViewState();
}

class _SettingsWorkspaceViewState extends State<SettingsWorkspaceView> {
  final TextEditingController _workspaceNameController =
      TextEditingController();

  @override
  void dispose() {
    _workspaceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceSettingsBloc>(
      create: (context) => WorkspaceSettingsBloc()
        ..add(WorkspaceSettingsEvent.initial(userProfile: widget.userProfile)),
      child: BlocConsumer<WorkspaceSettingsBloc, WorkspaceSettingsState>(
        listenWhen: (previous, current) =>
            previous.workspace?.name != current.workspace?.name,
        listener: (context, state) =>
            _workspaceNameController.text = state.workspace?.name ?? '',
        builder: (context, state) {
          return SettingsBody(
            children: [
              SettingsHeader(
                title: LocaleKeys.settings_workspace_title.tr(),
                description: LocaleKeys.settings_workspace_description.tr(),
              ),
              // We don't allow changing workspace name for local/offline
              if (widget.userProfile.authenticator !=
                  AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_workspace_workspaceName_title.tr(),
                  children: [
                    SettingsActionableInput(
                      controller: _workspaceNameController,
                      actions: [
                        SizedBox(
                          height: 48,
                          child: FlowyTextButton(
                            LocaleKeys.button_save.tr(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            radius: BorderRadius.circular(12),
                            fillColor: Theme.of(context).colorScheme.primary,
                            hoverColor: const Color(0xFF005483),
                            fontHoverColor: Colors.white,
                            onPressed: () => context
                                .read<WorkspaceSettingsBloc>()
                                .add(
                                  WorkspaceSettingsEvent.updateWorkspaceName(
                                    _workspaceNameController.text,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              if (state.workspace != null) ...[
                const SettingsCategorySpacer(),
                SettingsCategory(
                  title: LocaleKeys.settings_workspace_workspaceIcon_title.tr(),
                  description: LocaleKeys
                      .settings_workspace_workspaceIcon_description
                      .tr(),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 64,
                      width: 64,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: WorkspaceIcon(
                          workspace: state.workspace!,
                          iconSize: state.workspace?.icon.isNotEmpty == true
                              ? 46
                              : 20,
                          enableEdit: true,
                          onSelected: (emojiResult) =>
                              context.read<WorkspaceSettingsBloc>().add(
                                    WorkspaceSettingsEvent.updateWorkspaceIcon(
                                      emojiResult.emoji,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_appearance_title.tr(),
                children: const [
                  _AppearanceSelector(),
                ],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_theme_title.tr(),
                description:
                    LocaleKeys.settings_workspace_theme_description.tr(),
                children: const [
                  _ThemeDropdown(),
                ],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_workspaceFont_title.tr(),
                children: const [],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_textDirection_title.tr(),
                children: const [],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_dateTime_title.tr(),
                children: const [],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_language_title.tr(),
                children: const [],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeDropdown extends StatelessWidget {
  const _ThemeDropdown({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DynamicPluginBloc()..add(DynamicPluginEvent.load()),
      child: BlocBuilder<DynamicPluginBloc, DynamicPluginState>(
        buildWhen: (previous, current) => current is Ready,
        builder: (context, state) {
          final currentTheme =
              context.read<AppearanceSettingsCubit>().state.appTheme.themeName;

          final customThemes = state.maybeWhen(
            ready: (plugins) =>
                plugins.map((p) => p.theme).whereType<AppTheme>(),
            orElse: () => null,
          );

          return SettingsDropdown(
            onChanged: (appTheme) =>
                context.read<AppearanceSettingsCubit>().setTheme(appTheme),
            selectedOption: currentTheme,
            options: [
              ...AppTheme.builtins.map(
                (e) => DropdownMenuEntry<String>(
                  value: e.themeName,
                  label: e.themeName,
                ),
              ),
              ...?customThemes?.map(
                (e) => DropdownMenuEntry<String>(
                  value: e.themeName,
                  label: e.themeName,
                  trailingIcon: FlowyIconButton(
                    onPressed: () {
                      context.read<DynamicPluginBloc>().add(
                            DynamicPluginEvent.removePlugin(
                              name: e.themeName,
                            ),
                          );

                      if (currentTheme == e.themeName) {
                        context.read<AppearanceSettingsCubit>().setTheme(
                              AppTheme.builtins.first.themeName,
                            );
                      }
                    },
                    icon: const FlowySvg(FlowySvgs.delete_s),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.read<AppearanceSettingsCubit>().state.themeMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...ThemeMode.values.map(
          (t) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.read<AppearanceSettingsCubit>().setThemeMode(t),
              child: FlowyHover(
                style: HoverStyle.transparent(
                  foregroundColorOnHover:
                      AFThemeExtension.of(context).textColor,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: t == themeMode
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: Corners.s4Border,
                        image: DecorationImage(
                          image: AssetImage(
                            'assets/images/appearance/${t.name.toLowerCase()}.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const VSpace(6),
                    FlowyText.regular(
                      getLabel(t),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String getLabel(ThemeMode t) => switch (t) {
        ThemeMode.system =>
          LocaleKeys.settings_workspace_appearance_options_system.tr(),
        ThemeMode.light =>
          LocaleKeys.settings_workspace_appearance_options_light.tr(),
        ThemeMode.dark =>
          LocaleKeys.settings_workspace_appearance_options_dark.tr(),
      };
}
