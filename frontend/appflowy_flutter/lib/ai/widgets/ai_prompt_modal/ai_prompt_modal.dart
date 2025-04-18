import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_prompt_category_list.dart';
import 'ai_prompt_preview.dart';
import 'ai_prompt_visible_list.dart';

Future<AiPrompt?> showAiPromptModal(
  BuildContext context, {
  required AiPromptSelectorCubit aiPromptSelectorCubit,
}) async {
  return showDialog<AiPrompt?>(
    context: context,
    builder: (context) {
      return BlocProvider.value(
        value: aiPromptSelectorCubit,
        child: const AiPromptModal(),
      );
    },
  );
}

class AiPromptModal extends StatelessWidget {
  const AiPromptModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFModal(
      constraints: const BoxConstraints(
        maxWidth: 1200,
        maxHeight: 800,
      ),
      child: Column(
        children: [
          AFModalHeader(
            leading: Text(
              LocaleKeys.ai_customPrompt_browsePrompts.tr(),
              style: theme.textStyle.heading4.prominent(
                color: theme.textColorScheme.primary,
              ),
            ),
            trailing: [
              AFGhostButton.normal(
                onTap: () => Navigator.of(context).pop(),
                padding: EdgeInsets.all(theme.spacing.s),
                builder: (context, isHovering, disabled) {
                  return Center(
                    child: FlowySvg(
                      FlowySvgs.toast_close_s,
                      size: Size.square(20),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: AFModalBody(
              child: BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
                builder: (context, state) {
                  final theme = AppFlowyTheme.of(context);

                  return state.map(
                    loading: (_) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    ready: (_) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AiPromptCategoryList(
                              padding: EdgeInsetsDirectional.only(
                                top: theme.spacing.l,
                                bottom: theme.spacing.l,
                                end: theme.spacing.l,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: AiPromptVisibleList(
                              padding: EdgeInsets.symmetric(
                                vertical: theme.spacing.l,
                                horizontal: theme.spacing.l,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: BlocBuilder<AiPromptSelectorCubit,
                                AiPromptSelectorState>(
                              builder: (context, state) {
                                final selectedPrompt = state.maybeMap(
                                  ready: (state) {
                                    return state.visiblePrompts
                                        .firstWhereOrNull(
                                      (prompt) =>
                                          prompt.id == state.selectedPromptId,
                                    );
                                  },
                                  orElse: () => null,
                                );
                                if (selectedPrompt == null) {
                                  return const SizedBox.shrink();
                                }
                                return AiPromptPreview(
                                  prompt: selectedPrompt,
                                  padding: EdgeInsets.symmetric(
                                    vertical: theme.spacing.l,
                                    horizontal: theme.spacing.l,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          AFModalFooter(
            trailing: [
              AFFilledTextButton.primary(
                text: LocaleKeys.ai_customPrompt_usePrompt.tr(),
                onTap: () {
                  final selectedPrompt =
                      context.read<AiPromptSelectorCubit>().selectedPrompt;
                  if (selectedPrompt != null) {
                    Navigator.of(context).pop(selectedPrompt);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
