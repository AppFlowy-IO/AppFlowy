import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/presentation/widgets/dialog_v2.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_prompt_category_list.dart';
import 'ai_prompt_onboarding.dart';
import 'ai_prompt_preview.dart';
import 'ai_prompt_visible_list.dart';

Future<AiPrompt?> showAiPromptModal(
  BuildContext context, {
  required AiPromptSelectorCubit aiPromptSelectorCubit,
}) async {
  aiPromptSelectorCubit.loadCustomPrompts();

  return showDialog<AiPrompt?>(
    context: context,
    builder: (_) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: aiPromptSelectorCubit,
          ),
          BlocProvider.value(
            value: context.read<UserWorkspaceBloc>(),
          ),
        ],
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
      child: BlocListener<AiPromptSelectorCubit, AiPromptSelectorState>(
        listener: (context, state) {
          state.maybeMap(
            invalidDatabase: (_) {
              showLoadPromptFailedDialog(context);
            },
            orElse: () {},
          );
        },
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
                  padding: EdgeInsets.all(theme.spacing.xs),
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
                child:
                    BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
                  builder: (context, state) {
                    return state.maybeMap(
                      loading: (_) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      ready: (readyState) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(
                              child: AiPromptCategoryList(),
                            ),
                            if (readyState.isCustomPromptSectionSelected &&
                                readyState.customPromptDatabaseViewId == null)
                              const Expanded(
                                flex: 5,
                                child: Center(
                                  child: AiPromptOnboarding(),
                                ),
                              )
                            else ...[
                              const Expanded(
                                flex: 2,
                                child: AiPromptVisibleList(),
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
                                              prompt.id ==
                                              state.selectedPromptId,
                                        );
                                      },
                                      orElse: () => null,
                                    );
                                    if (selectedPrompt == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return AiPromptPreview(
                                      prompt: selectedPrompt,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showLoadPromptFailedDialog(
  BuildContext context,
) {
  showSimpleAFDialog(
    context: context,
    title: LocaleKeys.ai_customPrompt_invalidDatabase.tr(),
    content: LocaleKeys.ai_customPrompt_invalidDatabaseHelp.tr(),
    primaryAction: (
      LocaleKeys.button_ok.tr(),
      (context) {},
    ),
  );
}
