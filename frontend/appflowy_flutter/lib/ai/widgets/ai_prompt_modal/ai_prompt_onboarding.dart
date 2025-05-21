import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_prompt_database_modal.dart';

class AiPromptOnboarding extends StatelessWidget {
  const AiPromptOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.ai_customPrompt_customPrompt.tr(),
          style: theme.textStyle.heading3.standard(
            color: theme.textColorScheme.primary,
          ),
        ),
        VSpace(
          theme.spacing.s,
        ),
        Text(
          LocaleKeys.ai_customPrompt_databasePrompts.tr(),
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.secondary,
          ),
        ),
        VSpace(
          theme.spacing.xxl,
        ),
        AFFilledButton.primary(
          onTap: () async {
            final config = await changeCustomPromptDatabaseConfig(context);

            if (config != null && context.mounted) {
              context
                  .read<AiPromptSelectorCubit>()
                  .updateCustomPromptDatabaseConfiguration(config);
            }
          },
          builder: (context, isHovering, disabled) {
            return Text(
              LocaleKeys.ai_customPrompt_selectDatabase.tr(),
              style: theme.textStyle.body.enhanced(
                color: theme.textColorScheme.onFill,
              ),
            );
          },
        ),
      ],
    );
  }
}
