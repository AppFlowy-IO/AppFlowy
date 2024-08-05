import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIModelSelection extends StatelessWidget {
  const AIModelSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsAIBloc, SettingsAIState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FlowyText.medium(
                  LocaleKeys.settings_aiPage_keys_llmModelType.tr(),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Flexible(
                child: SettingsDropdown<AIModelPB>(
                  key: const Key('_AIModelSelection'),
                  onChanged: (model) => context
                      .read<SettingsAIBloc>()
                      .add(SettingsAIEvent.selectModel(model)),
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
              ),
            ],
          ),
        );
      },
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
    default:
      Log.error("Unknown AI model: $model, fallback to default");
      return "Default";
  }
}
