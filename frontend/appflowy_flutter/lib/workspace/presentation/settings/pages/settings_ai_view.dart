import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIFeatureOnlySupportedWhenUsingAppFlowyCloud extends StatelessWidget {
  const AIFeatureOnlySupportedWhenUsingAppFlowyCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: FlowyText(
        LocaleKeys.settings_aiPage_keys_loginToEnableAIFeature.tr(),
        maxLines: null,
        fontSize: 16,
        lineHeight: 1.6,
      ),
    );
  }
}

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
            description:
                LocaleKeys.settings_aiPage_keys_aiSettingsDescription.tr(),
            children: const [
              AIModelSeclection(),
              _AISearchToggle(value: false),
            ],
          );
        },
      ),
    );
  }
}

class AIModelSeclection extends StatelessWidget {
  const AIModelSeclection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowyText(
          LocaleKeys.settings_aiPage_keys_llmModel.tr(),
          fontSize: 14,
        ),
        const Spacer(),
        BlocBuilder<SettingsAIBloc, SettingsAIState>(
          builder: (context, state) {
            return Expanded(
              child: SettingsDropdown<AIModelPB>(
                key: const Key('AIModelDropdown'),
                expandWidth: false,
                onChanged: (format) {
                  context.read<SettingsAIBloc>().add(
                        SettingsAIEvent.selectModel(format),
                      );
                },
                selectedOption: state.userProfile.aiModel,
                options: _availableModels
                    .map(
                      (format) => buildDropdownMenuEntry<AIModelPB>(
                        context,
                        value: format,
                        label: _titleForAIModel(format),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

List<AIModelPB> _availableModels = [
  AIModelPB.DefaultModel,
  AIModelPB.Claude3Opus,
  AIModelPB.Claude3Sonnet,
  AIModelPB.GPT35,
  AIModelPB.GPT4o,
];

String _titleForAIModel(AIModelPB model) {
  switch (model) {
    case AIModelPB.DefaultModel:
      return "Default";
    case AIModelPB.Claude3Opus:
      return "Claude 3 Opus";
    case AIModelPB.Claude3Sonnet:
      return "Claude 3 Sonnet";
    case AIModelPB.GPT35:
      return "GPT-3.5";
    case AIModelPB.GPT4o:
      return "GPT-4o";
    case AIModelPB.LocalAIModel:
      return "Local";
    default:
      Log.error("Unknown AI model: $model, fallback to default");
      return "Default";
  }
}

class _AISearchToggle extends StatelessWidget {
  const _AISearchToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.regular(
            LocaleKeys.settings_aiPage_keys_enableAISearchTitle.tr(),
            fontSize: 16,
          ),
        ),
        const HSpace(16),
        BlocBuilder<SettingsAIBloc, SettingsAIState>(
          builder: (context, state) {
            if (state.aiSettings == null) {
              return const CircularProgressIndicator.adaptive();
            } else {
              return Toggle(
                value: state.enableSearchIndexing,
                onChanged: (_) {
                  context.read<SettingsAIBloc>().add(
                        const SettingsAIEvent.toggleAISearch(),
                      );
                },
              );
            }
          },
        ),
      ],
    );
  }
}
