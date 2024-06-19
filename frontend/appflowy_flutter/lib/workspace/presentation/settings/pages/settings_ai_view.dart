import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dashed_divider.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAIView extends StatelessWidget {
  const SettingsAIView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsAIBloc>(
      create: (context) =>
          SettingsAIBloc(userProfile)..add(const SettingsAIEvent.started()),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          return SettingsBody(
            title: LocaleKeys.settings_aiPage_title.tr(),
            children: [
              SettingsCategory(
                title: LocaleKeys.settings_aiPage_keys_title.tr(),
                children: [
                  SettingsInputField(
                    label: LocaleKeys.settings_aiPage_keys_openAILabel.tr(),
                    tooltip: LocaleKeys.settings_aiPage_keys_openAITooltip.tr(),
                    placeholder:
                        LocaleKeys.settings_aiPage_keys_openAIHint.tr(),
                    value: state.userProfile.openaiKey,
                    obscureText: true,
                    onSave: (key) => context
                        .read<SettingsAIBloc>()
                        .add(SettingsAIEvent.updateUserOpenAIKey(key)),
                  ),
                  SettingsInputField(
                    label:
                        LocaleKeys.settings_aiPage_keys_stabilityAILabel.tr(),
                    tooltip:
                        LocaleKeys.settings_aiPage_keys_stabilityAITooltip.tr(),
                    placeholder:
                        LocaleKeys.settings_aiPage_keys_stabilityAIHint.tr(),
                    value: state.userProfile.stabilityAiKey,
                    obscureText: true,
                    onSave: (key) => context
                        .read<SettingsAIBloc>()
                        .add(SettingsAIEvent.updateUserStabilityAIKey(key)),
                  ),
                  const SettingsDashedDivider(),
                  // TODO(Nathan): Propagate this value from `state`
                  const _AIChatToggle(value: false),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AIChatToggle extends StatelessWidget {
  const _AIChatToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: FlowyText.regular(
            'Enable AI Chat', // TODO(Nathan): Change and localize in `aiPage` in en.json
            fontSize: 16,
          ),
        ),
        const HSpace(16),
        Toggle(
          style: ToggleStyle.big,
          value: value,
          onChanged: (_) {
            // TODO(Nathan): Add this event
            // context
            //   .read<SettingsAIBloc>()
            //   .add(SettingsAIEvent.toggleAIChat());
          },
        ),
      ],
    );
  }
}
