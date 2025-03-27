import 'package:appflowy/ai/ai.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/af_dropdown_menu_entry.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dropdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIModelSelection extends StatelessWidget {
  const AIModelSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsAIBloc, SettingsAIState>(
      builder: (context, state) {
        if (state.availableModels == null) {
          return const SizedBox.shrink();
        }

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
                  selectedOption: state.availableModels!.selectedModel,
                  options: state.availableModels!.models
                      .map(
                        (model) => buildDropdownMenuEntry<AIModelPB>(
                          context,
                          value: model,
                          label: model.i18n,
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
