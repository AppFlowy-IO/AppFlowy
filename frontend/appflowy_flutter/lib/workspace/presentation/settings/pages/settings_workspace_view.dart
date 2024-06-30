import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
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
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dashed_divider.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_radio_select.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsWorkspaceView extends StatelessWidget {
  const SettingsWorkspaceView({
    super.key,
    required this.userProfile,
    this.workspaceMember,
  });

  final UserProfilePB userProfile;
  final WorkspaceMemberPB? workspaceMember;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceSettingsBloc>(
      create: (context) => WorkspaceSettingsBloc()
        ..add(WorkspaceSettingsEvent.initial(userProfile: userProfile)),
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
            autoSeparate: false,
            children: [
              // We don't allow changing workspace name/icon for local/offline
              if (userProfile.authenticator != AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_workspacePage_workspaceName_title
                      .tr(),
                  children: [_WorkspaceNameSetting(member: workspaceMember)],
                ),
                const SettingsCategorySpacer(),
                SettingsCategory(
                  title: LocaleKeys.settings_workspacePage_workspaceIcon_title
                      .tr(),
                  description: LocaleKeys
                      .settings_workspacePage_workspaceIcon_description
                      .tr(),
                  children: [
                    _WorkspaceIconSetting(
                      enableEdit: workspaceMember?.role.isOwner ?? false,
                      workspace: state.workspace,
                    ),
                  ],
                ),
                const SettingsCategorySpacer(),
              ],
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_appearance_title.tr(),
                children: const [AppearanceSelector()],
              ),
              const VSpace(16),
              // const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_theme_title.tr(),
                description:
                    LocaleKeys.settings_workspacePage_theme_description.tr(),
                children: const [
                  _ThemeDropdown(),
                  _DocumentCursorColorSetting(),
                  _DocumentSelectionColorSetting(),
                ],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title:
                    LocaleKeys.settings_workspacePage_workspaceFont_title.tr(),
                children: [
                  _FontSelectorDropdown(
                    currentFont:
                        context.read<AppearanceSettingsCubit>().state.font,
                  ),
                  SettingsDashedDivider(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SettingsCategory(
                    title: LocaleKeys.settings_workspacePage_textDirection_title
                        .tr(),
                    children: const [
                      TextDirectionSelect(),
                      EnableRTLItemsSwitcher(),
                    ],
                  ),
                ],
              ),
              const VSpace(16),
              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_layoutDirection_title
                    .tr(),
                children: const [_LayoutDirectionSelect()],
              ),
              const SettingsCategorySpacer(),

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
              const SettingsCategorySpacer(),

              SettingsCategory(
                title: LocaleKeys.settings_workspacePage_language_title.tr(),
                children: const [LanguageDropdown()],
              ),
              const SettingsCategorySpacer(),

              if (userProfile.authenticator != AuthenticatorPB.Local) ...[
                SingleSettingAction(
                  label: LocaleKeys.settings_workspacePage_manageWorkspace_title
                      .tr(),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: () => SettingsAlertDialog(
                    title: workspaceMember?.role.isOwner ?? false
                        ? LocaleKeys
                            .settings_workspacePage_deleteWorkspacePrompt_title
                            .tr()
                        : LocaleKeys
                            .settings_workspacePage_leaveWorkspacePrompt_title
                            .tr(),
                    subtitle: workspaceMember?.role.isOwner ?? false
                        ? LocaleKeys
                            .settings_workspacePage_deleteWorkspacePrompt_content
                            .tr()
                        : LocaleKeys
                            .settings_workspacePage_leaveWorkspacePrompt_content
                            .tr(),
                    isDangerous: true,
                    confirm: () {
                      context.read<WorkspaceSettingsBloc>().add(
                            workspaceMember?.role.isOwner ?? false
                                ? const WorkspaceSettingsEvent.deleteWorkspace()
                                : const WorkspaceSettingsEvent.leaveWorkspace(),
                          );
                      Navigator.of(context).pop();
                    },
                  ).show(context),
                  isDangerous: true,
                  buttonLabel: workspaceMember?.role.isOwner ?? false
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
  const _WorkspaceNameSetting({this.member});

  final WorkspaceMemberPB? member;

  @override
  State<_WorkspaceNameSetting> createState() => _WorkspaceNameSettingState();
}

class _WorkspaceNameSettingState extends State<_WorkspaceNameSetting> {
  final TextEditingController workspaceNameController = TextEditingController();
  final focusNode = FocusNode();
  Timer? _debounce;

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
        final newName = state.workspace?.name;
        if (newName != null && newName != workspaceNameController.text) {
          workspaceNameController.text = newName;
        }
      },
      builder: (_, state) {
        if (widget.member == null || !widget.member!.role.isOwner) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: FlowyText.regular(
              workspaceNameController.text,
              fontSize: 14,
            ),
          );
        }

        return Flexible(
          child: SettingsInputField(
            textController: workspaceNameController,
            value: workspaceNameController.text,
            focusNode: focusNode,
            onSave: (_) =>
                _saveWorkspaceName(name: workspaceNameController.text),
            onChanged: _debounceSaveName,
            hideActions: true,
          ),
        );
      },
    );
  }

  void _debounceSaveName(String name) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _saveWorkspaceName(name: name),
    );
  }

  void _saveWorkspaceName({required String name}) {
    if (name.isNotEmpty) {
      context
          .read<WorkspaceSettingsBloc>()
          .add(WorkspaceSettingsEvent.updateWorkspaceName(name));
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
          fontSize: 16.0,
          enableEdit: true,
          onSelected: (r) => context
              .read<WorkspaceSettingsBloc>()
              .add(WorkspaceSettingsEvent.updateWorkspaceIcon(r.emoji)),
        ),
      ),
    );
  }
}

@visibleForTesting
class TextDirectionSelect extends StatelessWidget {
  const TextDirectionSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        final selectedItem = state.textDirection ?? AppFlowyTextDirection.ltr;

        return SettingsRadioSelect<AppFlowyTextDirection>(
          onChanged: (item) {
            context
                .read<AppearanceSettingsCubit>()
                .setTextDirection(item.value);
            context
                .read<DocumentAppearanceCubit>()
                .syncDefaultTextDirection(item.value.name);
          },
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
                tooltip: LocaleKeys
                    .settings_workspacePage_theme_uploadCustomThemeTooltip
                    .tr(),
                icon: const FlowySvg(FlowySvgs.folder_m, size: Size.square(20)),
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
                icon: const FlowySvg(
                  FlowySvgs.restore_s,
                  size: Size.square(20),
                ),
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
                          : const _SelectedModeIndicator(),
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

class _SelectedModeIndicator extends StatelessWidget {
  const _SelectedModeIndicator();

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}

class _FontSelectorDropdown extends StatefulWidget {
  const _FontSelectorDropdown({required this.currentFont});

  final String currentFont;

  @override
  State<_FontSelectorDropdown> createState() => _FontSelectorDropdownState();
}

class _FontSelectorDropdownState extends State<_FontSelectorDropdown> {
  late final _options = [defaultFontFamily, ...GoogleFonts.asMap().keys];
  final _focusNode = FocusNode();
  final _controller = PopoverController();
  late final ScrollController _scrollController;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    const itemExtent = 32;
    final index = _options.indexOf(widget.currentFont);
    final newPosition = (index * itemExtent).toDouble();
    _scrollController = ScrollController(initialScrollOffset: newPosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textController.text = context
          .read<AppearanceSettingsCubit>()
          .state
          .font
          .fontFamilyDisplayName;
    });
  }

  @override
  void dispose() {
    _controller.close();
    _focusNode.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceSettingsCubit>().state;
    return LayoutBuilder(
      builder: (context, constraints) => AppFlowyPopover(
        margin: EdgeInsets.zero,
        controller: _controller,
        skipTraversal: true,
        triggerActions: PopoverTriggerFlags.none,
        onClose: () {
          _focusNode.unfocus();
          setState(() {});
        },
        direction: PopoverDirection.bottomWithLeftAligned,
        constraints: BoxConstraints(
          maxHeight: 150,
          maxWidth: constraints.maxWidth - 90,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
            ),
          ],
        ),
        popupBuilder: (_) => _FontListPopup(
          currentFont: appearance.font,
          scrollController: _scrollController,
          controller: _controller,
          options: _options,
          textController: _textController,
          focusNode: _focusNode,
        ),
        child: Row(
          children: [
            Expanded(
              child: TapRegion(
                behavior: HitTestBehavior.translucent,
                onTapOutside: (_) {
                  _focusNode.unfocus();
                  setState(() {});
                },
                child: Listener(
                  onPointerDown: (_) {
                    _focusNode.requestFocus();
                    setState(() {});
                    _controller.show();
                  },
                  child: FlowyTextField(
                    autoFocus: false,
                    focusNode: _focusNode,
                    controller: _textController,
                    decoration: InputDecoration(
                      suffixIcon: const MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(Icons.arrow_drop_down),
                      ),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: Corners.s8Border,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: Corners.s8Border,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        borderRadius: Corners.s8Border,
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        borderRadius: Corners.s8Border,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const HSpace(16),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        const FlowySvg(
                          FlowySvgs.restore_s,
                          size: Size.square(20),
                        ),
                        const HSpace(4),
                        FlowyText.regular(
                          LocaleKeys.settings_common_reset.tr(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontListPopup extends StatefulWidget {
  const _FontListPopup({
    required this.controller,
    required this.scrollController,
    required this.options,
    required this.currentFont,
    required this.textController,
    required this.focusNode,
  });

  final ScrollController scrollController;
  final List<String> options;
  final String currentFont;
  final TextEditingController textController;
  final FocusNode focusNode;
  final PopoverController controller;

  @override
  State<_FontListPopup> createState() => _FontListPopupState();
}

class _FontListPopupState extends State<_FontListPopup> {
  late List<String> _filteredOptions = widget.options;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextFieldChanged);
  }

  void _onTextFieldChanged() {
    final value = widget.textController.text;

    if (value.trim().isEmpty) {
      _filteredOptions = widget.options;
    } else {
      if (value.fontFamilyDisplayName ==
          widget.currentFont.fontFamilyDisplayName) {
        return;
      }

      _filteredOptions = widget.options
          .where(
            (f) =>
                f.toLowerCase().contains(value.trim().toLowerCase()) ||
                f.fontFamilyDisplayName
                    .toLowerCase()
                    .contains(value.trim().fontFamilyDisplayName.toLowerCase()),
          )
          .toList();

      // Default font family is "", but the display name is "System",
      // which means it's hard compared to other font families to find this one.
      if (!_filteredOptions.contains(defaultFontFamily) &&
          'system'.contains(value.trim().toLowerCase())) {
        _filteredOptions.insert(0, defaultFontFamily);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextFieldChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_filteredOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: FlowyText.medium(
                LocaleKeys.settings_workspacePage_workspaceFont_noFontHint.tr(),
              ),
            ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: _filteredOptions.length < 10,
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: _filteredOptions.length,
              separatorBuilder: (_, __) => const VSpace(4),
              itemBuilder: (context, index) {
                final font = _filteredOptions[index];
                final isSelected = widget.currentFont == font;
                return SizedBox(
                  height: 28,
                  child: ListTile(
                    selected: isSelected,
                    dense: true,
                    hoverColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.12),
                    selectedTileColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    minTileHeight: 28,
                    onTap: () {
                      context
                          .read<AppearanceSettingsCubit>()
                          .setFontFamily(font);

                      widget.textController.text = font.fontFamilyDisplayName;

                      // This is a workaround such that when dialog rebuilds due
                      // to font changing, the font selector won't retain focus.
                      widget.focusNode.parent?.requestFocus();

                      widget.controller.close();
                    },
                    title: Text(
                      font.fontFamilyDisplayName,
                      style: TextStyle(
                        color: AFThemeExtension.of(context).textColor,
                        fontFamily: getGoogleFontSafely(font).fontFamily,
                      ),
                    ),
                    trailing:
                        isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
          color: AFThemeExtension.of(context).onBackground,
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
    final textColor = AFThemeExtension.of(context).onBackground;
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
