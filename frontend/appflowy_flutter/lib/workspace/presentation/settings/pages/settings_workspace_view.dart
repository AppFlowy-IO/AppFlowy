import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/util/font_family_extension.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/date_time/time_format_ext.dart';
import 'package:appflowy/workspace/application/settings/workspace/workspace_settings_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/document_color_setting_button.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dashed_divider.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_radio_select.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_event.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsWorkspaceView extends StatefulWidget {
  const SettingsWorkspaceView({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  State<SettingsWorkspaceView> createState() => _SettingsWorkspaceViewState();
}

class _SettingsWorkspaceViewState extends State<SettingsWorkspaceView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceSettingsBloc>(
      create: (context) => WorkspaceSettingsBloc()
        ..add(WorkspaceSettingsEvent.initial(userProfile: widget.userProfile)),
      child: BlocConsumer<WorkspaceSettingsBloc, WorkspaceSettingsState>(
        listener: (context, state) {
          if (state.deleteWorkspace) {
            context.read<UserWorkspaceBloc>().add(
                  UserWorkspaceEvent.deleteWorkspace(
                    state.workspace!.workspaceId,
                  ),
                );
            Navigator.of(context).pop();
          }
          if (state.leaveWorkspace) {
            context.read<UserWorkspaceBloc>().add(
                  UserWorkspaceEvent.leaveWorkspace(
                    state.workspace!.workspaceId,
                  ),
                );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return SettingsBody(
            title: LocaleKeys.settings_workspacePage_title.tr(),
            description: LocaleKeys.settings_workspacePage_description.tr(),
            children: [
              // We don't allow changing workspace name/icon for local/offline
              if (widget.userProfile.authenticator !=
                  AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_workspacePage_workspaceName_title
                      .tr(),
                  children: const [_WorkspaceNameSetting()],
                ),
                SettingsCategory(
                  title: LocaleKeys.settings_workspacePage_workspaceIcon_title
                      .tr(),
                  description: LocaleKeys
                      .settings_workspacePage_workspaceIcon_description
                      .tr(),
                  children: [
                    _WorkspaceIconSetting(
                      enableEdit: state.myRole.isOwner,
                      workspace: state.workspace,
                    ),
                  ],
                ),
              ],
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_appearance_title.tr(),
                children: const [AppearanceSelector()],
              ),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_theme_title.tr(),
                description:
                    LocaleKeys.settings_workspacePage_theme_description.tr(),
                children: const [
                  _ThemeDropdown(),
                  SettingsDashedDivider(),
                  _DocumentCursorColorSetting(),
                  _DocumentSelectionColorSetting(),
                ],
              ),
              SettingsCategory(
                title:
                    LocaleKeys.settings_workspacePage_workspaceFont_title.tr(),
                children: const [_FontSelectorDropdown()],
              ),
              SettingsCategory(
                title:
                    LocaleKeys.settings_workspacePage_textDirection_title.tr(),
                children: const [
                  _TextDirectionSelect(),
                  EnableRTLItemsSwitcher(),
                ],
              ),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_layoutDirection_title
                    .tr(),
                children: const [_LayoutDirectionSelect()],
              ),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_dateTime_title.tr(),
                children: [
                  const _DateTimeFormatLabel(),
                  const _TimeFormatSwitcher(),
                  SettingsDashedDivider(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const _DateFormatDropdown(),
                ],
              ),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_language_title.tr(),
                children: const [LanguageDropdown()],
              ),
              if (widget.userProfile.authenticator !=
                  AuthenticatorPB.Local) ...[
                SingleSettingAction(
                  label: LocaleKeys.settings_workspacePage_manageWorkspace_title
                      .tr(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: () => SettingsAlertDialog(
                    title: state.myRole.isOwner
                        ? LocaleKeys
                            .settings_workspacePage_deleteWorkspacePrompt_title
                            .tr()
                        : LocaleKeys
                            .settings_workspacePage_leaveWorkspacePrompt_title
                            .tr(),
                    subtitle: state.myRole.isOwner
                        ? LocaleKeys
                            .settings_workspacePage_deleteWorkspacePrompt_content
                            .tr()
                        : LocaleKeys
                            .settings_workspacePage_leaveWorkspacePrompt_content
                            .tr(),
                    isDangerous: true,
                    confirm: () {
                      context.read<WorkspaceSettingsBloc>().add(
                            state.myRole.isOwner
                                ? const WorkspaceSettingsEvent.deleteWorkspace()
                                : const WorkspaceSettingsEvent.leaveWorkspace(),
                          );
                      Navigator.of(context).pop();
                    },
                  ).show(context),
                  isDangerous: true,
                  buttonLabel: state.myRole.isOwner
                      ? LocaleKeys
                          .settings_workspacePage_manageWorkspace_deleteWorkspace
                          .tr()
                      : LocaleKeys
                          .settings_workspacePage_manageWorkspace_leaveWorkspace
                          .tr(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceNameSetting extends StatefulWidget {
  const _WorkspaceNameSetting();

  @override
  State<_WorkspaceNameSetting> createState() => _WorkspaceNameSettingState();
}

class _WorkspaceNameSettingState extends State<_WorkspaceNameSetting> {
  final TextEditingController workspaceNameController = TextEditingController();
  late final FocusNode focusNode;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            isEditing &&
            mounted) {
          setState(() => isEditing = false);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    )..addListener(() {
        if (!focusNode.hasFocus && isEditing && mounted) {
          _saveWorkspaceName(name: workspaceNameController.text);
          setState(() => isEditing = false);
        }
      });
  }

  @override
  void dispose() {
    focusNode.dispose();
    workspaceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkspaceSettingsBloc, WorkspaceSettingsState>(
      listener: (_, state) {
        if ((state.workspace?.name ?? '') != workspaceNameController.text) {
          workspaceNameController.text = state.workspace?.name ?? '';
        }
      },
      builder: (_, state) {
        if (isEditing) {
          return Flexible(
            child: SettingsInputField(
              textController: workspaceNameController,
              value: workspaceNameController.text,
              focusNode: focusNode..requestFocus(),
              onCancel: () => setState(() => isEditing = false),
              onSave: (_) {
                _saveWorkspaceName(name: workspaceNameController.text);
                setState(() => isEditing = false);
              },
            ),
          );
        }

        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: FlowyText.regular(
                workspaceNameController.text,
                fontSize: 14,
              ),
            ),
            if (state.myRole.isOwner) ...[
              const HSpace(4),
              FlowyTooltip(
                message: 'Edit workspace name',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isEditing = true),
                  child: const FlowyHover(
                    resetHoverOnRebuild: false,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: FlowySvg(FlowySvgs.edit_s),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _saveWorkspaceName({
    required String name,
  }) {
    if (name.isNotEmpty) {
      context.read<WorkspaceSettingsBloc>().add(
            WorkspaceSettingsEvent.updateWorkspaceName(name),
          );

      if (context.mounted) {
        showSnackBarMessage(
          context,
          LocaleKeys.settings_workspacePage_workspaceName_savedMessage.tr(),
        );
      }
    }
  }
}

@visibleForTesting
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        return SettingsDropdown<Locale>(
          key: const Key('LanguageDropdown'),
          expandWidth: false,
          onChanged: (locale) => context
              .read<AppearanceSettingsCubit>()
              .setLocale(context, locale),
          selectedOption: state.locale,
          options: EasyLocalization.of(context)!
              .supportedLocales
              .map(
                (locale) => buildDropdownMenuEntry<Locale>(
                  context,
                  selectedValue: state.locale,
                  value: locale,
                  label: languageFromLocale(locale),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _WorkspaceIconSetting extends StatelessWidget {
  const _WorkspaceIconSetting({required this.enableEdit, this.workspace});

  final bool enableEdit;
  final UserWorkspacePB? workspace;

  @override
  Widget build(BuildContext context) {
    if (workspace == null) {
      return const SizedBox(
        height: 64,
        width: 64,
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: WorkspaceIcon(
          workspace: workspace!,
          iconSize: workspace!.icon.isNotEmpty == true ? 46 : 20,
          enableEdit: enableEdit,
          onSelected: (r) => context
              .read<WorkspaceSettingsBloc>()
              .add(WorkspaceSettingsEvent.updateWorkspaceIcon(r.emoji)),
        ),
      ),
    );
  }
}

class _TextDirectionSelect extends StatelessWidget {
  const _TextDirectionSelect();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        final selectedItem = state.textDirection ?? AppFlowyTextDirection.auto;

        return SettingsRadioSelect<AppFlowyTextDirection>(
          onChanged: (item) => context
              .read<AppearanceSettingsCubit>()
              .setTextDirection(item.value),
          items: [
            SettingsRadioItem(
              value: AppFlowyTextDirection.ltr,
              icon: const FlowySvg(FlowySvgs.textdirection_ltr_m),
              label: LocaleKeys.settings_workspacePage_textDirection_leftToRight
                  .tr(),
              isSelected: selectedItem == AppFlowyTextDirection.ltr,
            ),
            SettingsRadioItem(
              value: AppFlowyTextDirection.rtl,
              icon: const FlowySvg(FlowySvgs.textdirection_rtl_m),
              label: LocaleKeys.settings_workspacePage_textDirection_rightToLeft
                  .tr(),
              isSelected: selectedItem == AppFlowyTextDirection.rtl,
            ),
            SettingsRadioItem(
              value: AppFlowyTextDirection.auto,
              icon: const FlowySvg(FlowySvgs.textdirection_auto_m),
              label: LocaleKeys.settings_workspacePage_textDirection_auto.tr(),
              isSelected: selectedItem == AppFlowyTextDirection.auto,
            ),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class EnableRTLItemsSwitcher extends StatelessWidget {
  const EnableRTLItemsSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.regular(
            LocaleKeys.settings_workspacePage_textDirection_enableRTLItems.tr(),
            fontSize: 16,
          ),
        ),
        const HSpace(16),
        Toggle(
          style: ToggleStyle.big,
          value: context
              .watch<AppearanceSettingsCubit>()
              .state
              .enableRtlToolbarItems,
          onChanged: (value) => context
              .read<AppearanceSettingsCubit>()
              .setEnableRTLToolbarItems(!value),
        ),
      ],
    );
  }
}

class _LayoutDirectionSelect extends StatelessWidget {
  const _LayoutDirectionSelect();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        return SettingsRadioSelect<LayoutDirection>(
          onChanged: (item) => context
              .read<AppearanceSettingsCubit>()
              .setLayoutDirection(item.value),
          items: [
            SettingsRadioItem(
              value: LayoutDirection.ltrLayout,
              icon: const FlowySvg(FlowySvgs.textdirection_ltr_m),
              label: LocaleKeys
                  .settings_workspacePage_layoutDirection_leftToRight
                  .tr(),
              isSelected: state.layoutDirection == LayoutDirection.ltrLayout,
            ),
            SettingsRadioItem(
              value: LayoutDirection.rtlLayout,
              icon: const FlowySvg(FlowySvgs.textdirection_rtl_m),
              label: LocaleKeys
                  .settings_workspacePage_layoutDirection_rightToLeft
                  .tr(),
              isSelected: state.layoutDirection == LayoutDirection.rtlLayout,
            ),
          ],
        );
      },
    );
  }
}

class _DateFormatDropdown extends StatelessWidget {
  const _DateFormatDropdown();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowyText.regular(
                LocaleKeys.settings_workspacePage_dateTime_dateFormat_label
                    .tr(),
                fontSize: 16,
              ),
              const VSpace(8),
              SettingsDropdown<UserDateFormatPB>(
                key: const Key('DateFormatDropdown'),
                expandWidth: false,
                onChanged: (format) => context
                    .read<AppearanceSettingsCubit>()
                    .setDateFormat(format),
                selectedOption: state.dateFormat,
                options: UserDateFormatPB.values
                    .map(
                      (format) => buildDropdownMenuEntry<UserDateFormatPB>(
                        context,
                        value: format,
                        label: _formatLabel(format),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLabel(UserDateFormatPB format) => switch (format) {
        UserDateFormatPB.Locally =>
          LocaleKeys.settings_workspacePage_dateTime_dateFormat_local.tr(),
        UserDateFormatPB.US =>
          LocaleKeys.settings_workspacePage_dateTime_dateFormat_us.tr(),
        UserDateFormatPB.ISO =>
          LocaleKeys.settings_workspacePage_dateTime_dateFormat_iso.tr(),
        UserDateFormatPB.Friendly =>
          LocaleKeys.settings_workspacePage_dateTime_dateFormat_friendly.tr(),
        UserDateFormatPB.DayMonthYear =>
          LocaleKeys.settings_workspacePage_dateTime_dateFormat_dmy.tr(),
        _ => "Unknown format",
      };
}

class _DateTimeFormatLabel extends StatelessWidget {
  const _DateTimeFormatLabel();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        return FlowyText.regular(
          LocaleKeys.settings_workspacePage_dateTime_example.tr(
            args: [
              state.dateFormat.formatDate(now, false),
              state.timeFormat.formatTime(now),
              now.timeZoneName,
            ],
          ),
          maxLines: 2,
          fontSize: 16,
          color: AFThemeExtension.of(context).secondaryTextColor,
        );
      },
    );
  }
}

class _TimeFormatSwitcher extends StatelessWidget {
  const _TimeFormatSwitcher();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.regular(
            LocaleKeys.settings_workspacePage_dateTime_24HourTime.tr(),
            fontSize: 16,
          ),
        ),
        const HSpace(16),
        Toggle(
          style: ToggleStyle.big,
          value: context.watch<AppearanceSettingsCubit>().state.timeFormat ==
              UserTimeFormatPB.TwentyFourHour,
          onChanged: (value) =>
              context.read<AppearanceSettingsCubit>().setTimeFormat(
                    value
                        ? UserTimeFormatPB.TwelveHour
                        : UserTimeFormatPB.TwentyFourHour,
                  ),
        ),
      ],
    );
  }
}

class _ThemeDropdown extends StatelessWidget {
  const _ThemeDropdown();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DynamicPluginBloc>(
      create: (context) => DynamicPluginBloc()..add(DynamicPluginEvent.load()),
      child: BlocBuilder<DynamicPluginBloc, DynamicPluginState>(
        buildWhen: (_, current) => current is Ready,
        builder: (context, state) {
          final appearance = context.watch<AppearanceSettingsCubit>().state;
          final isLightMode = Theme.of(context).brightness == Brightness.light;

          final customThemes = state.whenOrNull(
            ready: (ps) => ps.map((p) => p.theme).whereType<AppTheme>(),
          );

          return SettingsDropdown<String>(
            key: const Key('ThemeSelectorDropdown'),
            actions: [
              SettingAction(
                tooltip: 'Upload a custom theme',
                icon: const FlowySvg(FlowySvgs.folder_m, size: Size.square(16)),
                onPressed: () => Dialogs.show(
                  context,
                  child: BlocProvider<DynamicPluginBloc>.value(
                    value: context.read<DynamicPluginBloc>(),
                    child: const FlowyDialog(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: ThemeUploadWidget(),
                    ),
                  ),
                ).then((val) {
                  if (val != null) {
                    showSnackBarMessage(
                      context,
                      LocaleKeys.settings_appearance_themeUpload_uploadSuccess
                          .tr(),
                    );
                  }
                }),
              ),
              SettingAction(
                icon: const FlowySvg(FlowySvgs.restore_s),
                label: LocaleKeys.settings_common_reset.tr(),
                onPressed: () => context
                    .read<AppearanceSettingsCubit>()
                    .setTheme(AppTheme.builtins.first.themeName),
              ),
            ],
            onChanged: (theme) =>
                context.read<AppearanceSettingsCubit>().setTheme(theme),
            selectedOption: appearance.appTheme.themeName,
            options: [
              ...AppTheme.builtins.map(
                (t) {
                  final theme = isLightMode ? t.lightTheme : t.darkTheme;

                  return buildDropdownMenuEntry<String>(
                    context,
                    selectedValue: appearance.appTheme.themeName,
                    value: t.themeName,
                    label: t.themeName,
                    leadingWidget: _ThemeLeading(color: theme.sidebarBg),
                  );
                },
              ),
              ...?customThemes?.map(
                (t) {
                  final theme = isLightMode ? t.lightTheme : t.darkTheme;

                  return buildDropdownMenuEntry<String>(
                    context,
                    selectedValue: appearance.appTheme.themeName,
                    value: t.themeName,
                    label: t.themeName,
                    leadingWidget: _ThemeLeading(color: theme.sidebarBg),
                    trailingWidget: FlowyIconButton(
                      icon: const FlowySvg(FlowySvgs.delete_s),
                      iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        context.read<DynamicPluginBloc>().add(
                              DynamicPluginEvent.removePlugin(
                                name: t.themeName,
                              ),
                            );

                        if (appearance.appTheme.themeName == t.themeName) {
                          context
                              .read<AppearanceSettingsCubit>()
                              .setTheme(AppTheme.builtins.first.themeName);
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeLeading extends StatelessWidget {
  const _ThemeLeading({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: Corners.s4Border,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

@visibleForTesting
class AppearanceSelector extends StatelessWidget {
  const AppearanceSelector({super.key});

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
                          fit: BoxFit.cover,
                          image: AssetImage(
                            'assets/images/appearance/${t.name.toLowerCase()}.png',
                          ),
                        ),
                      ),
                      child: t != themeMode
                          ? null
                          : Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Material(
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      height: 16,
                                      width: 16,
                                      child: const FlowySvg(
                                        FlowySvgs.settings_selected_theme_m,
                                        size: Size.square(16),
                                        blendMode: BlendMode.dstIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const VSpace(6),
                    FlowyText.regular(getLabel(t), textAlign: TextAlign.center),
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
          LocaleKeys.settings_workspacePage_appearance_options_system.tr(),
        ThemeMode.light =>
          LocaleKeys.settings_workspacePage_appearance_options_light.tr(),
        ThemeMode.dark =>
          LocaleKeys.settings_workspacePage_appearance_options_dark.tr(),
      };
}

class _FontSelectorDropdown extends StatelessWidget {
  const _FontSelectorDropdown();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceSettingsCubit>().state;
    return SettingsDropdown<String>(
      key: const Key('FontSelectorDropdown'),
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context
              .read<AppearanceSettingsCubit>()
              .setFontFamily(defaultFontFamily),
          child: SizedBox(
            height: 26,
            child: FlowyHover(
              resetHoverOnRebuild: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    const FlowySvg(FlowySvgs.restore_s),
                    const HSpace(4),
                    FlowyText.regular(LocaleKeys.settings_common_reset.tr()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      onChanged: (font) =>
          context.read<AppearanceSettingsCubit>().setFontFamily(font),
      selectedOption: appearance.font,
      options: [defaultFontFamily, ...GoogleFonts.asMap().keys]
          .map(
            (font) => buildDropdownMenuEntry<String>(
              context,
              selectedValue: appearance.font,
              value: font,
              label: font.fontFamilyDisplayName,
              fontFamily: font,
            ),
          )
          .toList(),
    );
  }
}

class _DocumentCursorColorSetting extends StatelessWidget {
  const _DocumentCursorColorSetting();

  @override
  Widget build(BuildContext context) {
    final label =
        LocaleKeys.settings_appearance_documentSettings_cursorColor.tr();
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
        return SettingListTile(
          label: label,
          resetButtonKey: const Key('DocumentCursorColorResetButton'),
          onResetRequested: () => context
            ..read<AppearanceSettingsCubit>().resetDocumentCursorColor()
            ..read<DocumentAppearanceCubit>().syncCursorColor(null),
          trailing: [
            DocumentColorSettingButton(
              key: const Key('DocumentCursorColorSettingButton'),
              currentColor: state.cursorColor ??
                  DefaultAppearanceSettings.getDefaultCursorColor(context),
              previewWidgetBuilder: (color) => _CursorColorValueWidget(
                cursorColor: color ??
                    DefaultAppearanceSettings.getDefaultCursorColor(context),
              ),
              dialogTitle: label,
              onApply: (color) => context
                ..read<AppearanceSettingsCubit>().setDocumentCursorColor(color)
                ..read<DocumentAppearanceCubit>().syncCursorColor(color),
            ),
          ],
        );
      },
    );
  }
}

class _CursorColorValueWidget extends StatelessWidget {
  const _CursorColorValueWidget({required this.cursorColor});

  final Color cursorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(color: cursorColor, width: 2, height: 16),
        FlowyText(
          LocaleKeys.appName.tr(),
          // To avoid the text color changes when it is hovered in dark mode
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ],
    );
  }
}

class _DocumentSelectionColorSetting extends StatelessWidget {
  const _DocumentSelectionColorSetting();

  @override
  Widget build(BuildContext context) {
    final label =
        LocaleKeys.settings_appearance_documentSettings_selectionColor.tr();

    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
        return SettingListTile(
          label: label,
          resetButtonKey: const Key('DocumentSelectionColorResetButton'),
          onResetRequested: () => context
            ..read<AppearanceSettingsCubit>().resetDocumentSelectionColor()
            ..read<DocumentAppearanceCubit>().syncSelectionColor(null),
          trailing: [
            DocumentColorSettingButton(
              currentColor: state.selectionColor ??
                  DefaultAppearanceSettings.getDefaultSelectionColor(context),
              previewWidgetBuilder: (color) => _SelectionColorValueWidget(
                selectionColor: color ??
                    DefaultAppearanceSettings.getDefaultSelectionColor(context),
              ),
              dialogTitle: label,
              onApply: (c) => context
                ..read<AppearanceSettingsCubit>().setDocumentSelectionColor(c)
                ..read<DocumentAppearanceCubit>().syncSelectionColor(c),
            ),
          ],
        );
      },
    );
  }
}

class _SelectionColorValueWidget extends StatelessWidget {
  const _SelectionColorValueWidget({required this.selectionColor});

  final Color selectionColor;

  @override
  Widget build(BuildContext context) {
    // To avoid the text color changes when it is hovered in dark mode
    final textColor = Theme.of(context).colorScheme.onBackground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: selectionColor,
          child: FlowyText(
            LocaleKeys.settings_appearance_documentSettings_app.tr(),
            color: textColor,
          ),
        ),
        FlowyText(
          LocaleKeys.settings_appearance_documentSettings_flowy.tr(),
          color: textColor,
        ),
      ],
    );
  }
}
