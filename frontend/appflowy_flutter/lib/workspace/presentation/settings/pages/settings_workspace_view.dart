import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/date_time/time_format_ext.dart';
import 'package:appflowy/workspace/application/settings/workspace/workspace_settings_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_actionable_input.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dotted_divider.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_radio_select.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
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
                    if (state.workspace != null)
                      _WorkspaceIconSetting(workspace: state.workspace!),
                  ],
                ),
              ],
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_appearance_title.tr(),
                children: const [_AppearanceSelector()],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_theme_title.tr(),
                description:
                    LocaleKeys.settings_workspace_theme_description.tr(),
                children: const [_ThemeDropdown()],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_workspaceFont_title.tr(),
                children: const [_FontSelectorDropdown()],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_textDirection_title.tr(),
                children: const [_TextDirectionSelect()],
              ),
              const SettingsCategorySpacer(),
              SettingsCategory(
                title: LocaleKeys.settings_workspace_dateTime_title.tr(),
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
                title: LocaleKeys.settings_workspace_language_title.tr(),
                children: const [_LanguageDropdown()],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) {
        return SettingsDropdown<Locale>(
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
  const _WorkspaceIconSetting({required this.workspace});

  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
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
          workspace: workspace,
          iconSize: workspace.icon.isNotEmpty == true ? 46 : 20,
          enableEdit: true,
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
        // TODO(Lucas): Do we even use TextDirection or do we just rely on LayoutDirection?
        //  Also if we rely on LayoutDirection, auto does not exist, but we can implement it using
        //  Bidi.isRtlLanguage(language) from Intl package.
        return SettingsRadioSelect<AppFlowyTextDirection>(
          onChanged: (item) => context
              .read<AppearanceSettingsCubit>()
              .setTextDirection(item.value),
          items: [
            SettingsRadioItem(
              value: AppFlowyTextDirection.ltr,
              icon: const FlowySvg(FlowySvgs.textdirection_ltr_m),
              label:
                  LocaleKeys.settings_workspace_textDirection_leftToRight.tr(),
              isSelected: state.textDirection == AppFlowyTextDirection.ltr,
            ),
            SettingsRadioItem(
              value: AppFlowyTextDirection.rtl,
              icon: const FlowySvg(FlowySvgs.textdirection_rtl_m),
              label:
                  LocaleKeys.settings_workspace_textDirection_rightToLeft.tr(),
              isSelected: state.textDirection == AppFlowyTextDirection.rtl,
            ),
            SettingsRadioItem(
              value: AppFlowyTextDirection.auto,
              icon: const FlowySvg(FlowySvgs.textdirection_auto_m),
              label: LocaleKeys.settings_workspace_textDirection_auto.tr(),
              isSelected: state.textDirection == AppFlowyTextDirection.auto,
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
                LocaleKeys.settings_workspace_dateTime_dateFormat_label.tr(),
                fontSize: 16,
              ),
              const VSpace(8),
              SettingsDropdown<UserDateFormatPB>(
                expandWidth: false,
                onChanged: (format) => context
                    .read<AppearanceSettingsCubit>()
                    .setDateFormat(format),
                selectedOption: state.dateFormat,
                options: UserDateFormatPB.values
                    .map(
                      (f) => buildDropdownMenuEntry<UserDateFormatPB>(
                        context,
                        value: f,
                        label: _formatLabel(f),
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
          LocaleKeys.settings_workspace_dateTime_dateFormat_local.tr(),
        UserDateFormatPB.US =>
          LocaleKeys.settings_workspace_dateTime_dateFormat_us.tr(),
        UserDateFormatPB.ISO =>
          LocaleKeys.settings_workspace_dateTime_dateFormat_iso.tr(),
        UserDateFormatPB.Friendly =>
          LocaleKeys.settings_workspace_dateTime_dateFormat_friendly.tr(),
        UserDateFormatPB.DayMonthYear =>
          LocaleKeys.settings_workspace_dateTime_dateFormat_dmy.tr(),
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
          LocaleKeys.settings_workspace_dateTime_example.tr(
            args: [
              state.dateFormat.formatDate(now, false),
              state.timeFormat.formatTime(now),
              now.timeZoneName,
            ],
          ),
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
            LocaleKeys.settings_workspace_dateTime_24HourTime.tr(),
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
    return BlocProvider(
      create: (context) => DynamicPluginBloc()..add(DynamicPluginEvent.load()),
      child: BlocBuilder<DynamicPluginBloc, DynamicPluginState>(
        buildWhen: (previous, current) => current is Ready,
        builder: (context, state) {
          final appearance = context.watch<AppearanceSettingsCubit>().state;
          final isLightMode = Theme.of(context).brightness == Brightness.light;

          final customThemes = state.maybeWhen(
            ready: (plugins) =>
                plugins.map((p) => p.theme).whereType<AppTheme>(),
            orElse: () => null,
          );

          return SettingsDropdown(
            actions: [
              SettingAction(
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
                icon: const FlowySvg(FlowySvgs.folder_m, size: Size.square(16)),
              ),
              SettingAction(
                onPressed: () => context
                    .read<AppearanceSettingsCubit>()
                    .setTheme(AppTheme.builtins.first.themeName),
                icon: const FlowySvg(FlowySvgs.restore_s),
                label: LocaleKeys.settings_common_reset.tr(),
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

class SettingAction extends StatelessWidget {
  const SettingAction({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: 26,
        child: FlowyHover(
          resetHoverOnRebuild: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                icon,
                if (label != null) ...[
                  const HSpace(4),
                  FlowyText.regular(label!),
                ],
              ],
            ),
          ),
        ),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
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

class _FontSelectorDropdown extends StatelessWidget {
  const _FontSelectorDropdown();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceSettingsCubit>().state;

    return SettingsDropdown(
      actions: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context
              .read<AppearanceSettingsCubit>()
              .setFontFamily(builtInFontFamily),
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
      options: [
        ...GoogleFonts.asMap().keys.toList().map(
              (f) => buildDropdownMenuEntry<String>(
                context,
                selectedValue: appearance.font,
                value: f,
                label: f,
              ),
            ),
      ],
    );
  }
}
