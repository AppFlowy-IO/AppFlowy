import 'package:appflowy/workspace/application/settings/ai/setting_local_ai_bloc.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
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
              LocalAIConfiguration(),
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
                onChanged: (_) => context
                    .read<SettingsAIBloc>()
                    .add(const SettingsAIEvent.toggleAISearch()),
              );
            }
          },
        ),
      ],
    );
  }
}

class LocalAIConfiguration extends StatelessWidget {
  const LocalAIConfiguration({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingsAILocalBloc()..add(const SettingsAILocalEvent.started()),
      child: BlocBuilder<SettingsAILocalBloc, SettingsAILocalState>(
        builder: (context, state) {
          return state.loadingState.when(
            loading: () {
              return const SizedBox.shrink();
            },
            finish: () {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AIConfigurateTextField(
                    title: 'chat bin path',
                    hitText: '',
                    errorText: state.chatBinPathError ?? '',
                    value: state.aiSettings?.chatBinPath ?? '',
                    onChanged: (value) {
                      context.read<SettingsAILocalBloc>().add(
                            SettingsAILocalEvent.updateChatBin(value),
                          );
                    },
                  ),
                  const VSpace(16),
                  AIConfigurateTextField(
                    title: 'chat model path',
                    hitText: '',
                    errorText: state.chatModelPathError ?? '',
                    value: state.aiSettings?.chatModelPath ?? '',
                    onChanged: (value) {
                      context.read<SettingsAILocalBloc>().add(
                            SettingsAILocalEvent.updateChatModelPath(value),
                          );
                    },
                  ),
                  const VSpace(16),
                  Toggle(
                    value: state.localAIEnabled,
                    onChanged: (_) => context
                        .read<SettingsAILocalBloc>()
                        .add(const SettingsAILocalEvent.toggleLocalAI()),
                  ),
                  const VSpace(16),
                  FlowyButton(
                    disable: !state.saveButtonEnabled,
                    text: const FlowyText("save"),
                    onTap: () {
                      context.read<SettingsAILocalBloc>().add(
                            const SettingsAILocalEvent.saveSetting(),
                          );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class AIConfigurateTextField extends StatelessWidget {
  const AIConfigurateTextField({
    required this.title,
    required this.hitText,
    required this.errorText,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String hitText;
  final String errorText;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          title,
        ),
        const VSpace(8),
        RoundedInputField(
            hintText: hitText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            normalBorderColor: Theme.of(context).colorScheme.outline,
            errorBorderColor: Theme.of(context).colorScheme.error,
            cursorColor: Theme.of(context).colorScheme.primary,
            errorText: errorText,
            initialValue: value,
            onChanged: onChanged),
      ],
    );
  }
}
