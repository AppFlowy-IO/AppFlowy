import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ai_prompt_modal/ai_prompt_modal.dart';

class BrowsePromptsButton extends StatelessWidget {
  const BrowsePromptsButton({
    super.key,
    required this.onSelectPrompt,
  });

  final void Function(AiPrompt) onSelectPrompt;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.ai_customPrompt_browsePrompts.tr(),
      child: BlocProvider(
        create: (context) => AiPromptSelectorCubit(),
        child: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () async {
                final prompt = await showAiPromptModal(
                  context,
                  aiPromptSelectorCubit: context.read<AiPromptSelectorCubit>(),
                );
                if (context.mounted) {
                  context.read<AiPromptSelectorCubit>().reset();
                }
                if (prompt != null && context.mounted) {
                  onSelectPrompt(prompt);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: DesktopAIPromptSizes.actionBarButtonSize,
                child: FlowyHover(
                  style: const HoverStyle(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(4.0),
                    child: Center(
                      child: FlowyText(
                        LocaleKeys.ai_customPrompt_browsePrompts.tr(),
                        fontSize: 12,
                        figmaLineHeight: 16,
                        color: Theme.of(context).hintColor,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
