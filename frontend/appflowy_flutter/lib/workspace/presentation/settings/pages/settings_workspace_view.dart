import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/workspace/workspace_settings_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_actionable_input.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
              const SettingsHeader(
                title: 'Workspace',
                description:
                    'Customize your workspace appearance, theme, font, text layout, date, time, and language.',
              ),
              // We don't allow changing workspace name for local/offline
              if (widget.userProfile.authenticator !=
                  AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: 'Workspace name',
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
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Workspace icon',
                description:
                    'Customize your workspace appearance, theme, font, text layout, date, time, and language.',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Appearance',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Theme',
                description:
                    'Select a preset theme, or upload your own custom theme.',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Workspace font',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Text direction',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Date & time',
                children: [],
              ),
              const SettingsCategorySpacer(),
              const SettingsCategory(
                title: 'Language',
                children: [],
              ),
            ],
          );
        },
      ),
    );
  }
}
