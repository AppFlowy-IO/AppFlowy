import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class AiPromptPreview extends StatelessWidget {
  const AiPromptPreview({
    super.key,
    required this.prompt,
    required this.padding,
  });

  final AiPrompt prompt;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return SelectionArea(
      child: ListView(
        padding: padding,
        children: [
          SelectionContainer.disabled(
            child: Text(
              prompt.name,
              style: theme.textStyle.headline.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
          ),
          VSpace(theme.spacing.xs),
          SelectionContainer.disabled(
            child: Text(
              LocaleKeys.ai_customPrompt_prompt.tr(),
              style: theme.textStyle.heading4.standard(
                color: theme.textColorScheme.primary,
              ),
            ),
          ),
          VSpace(theme.spacing.xs),
          _PromptContent(
            prompt: prompt,
          ),
          VSpace(theme.spacing.xl),
          if (prompt.example.isNotEmpty) ...[
            SelectionContainer.disabled(
              child: Text(
                LocaleKeys.ai_customPrompt_example.tr(),
                style: theme.textStyle.heading4.standard(
                  color: theme.textColorScheme.primary,
                ),
              ),
            ),
            VSpace(theme.spacing.xs),
            _PromptExample(
              prompt: prompt,
            ),
            VSpace(theme.spacing.xl),
          ],
          if (prompt.sampleResponse.isNotEmpty) ...[
            SelectionContainer.disabled(
              child: Text(
                LocaleKeys.ai_customPrompt_sampleOutput.tr(),
                style: theme.textStyle.heading4.standard(
                  color: theme.textColorScheme.primary,
                ),
              ),
            ),
            VSpace(theme.spacing.xs),
            _PromptSampleOutput(
              prompt: prompt,
            ),
          ],
        ],
      ),
    );
  }
}

class _PromptContent extends StatelessWidget {
  const _PromptContent({
    required this.prompt,
  });

  final AiPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final textSpans = _buildTextSpans(context, prompt.content);

    return Container(
      padding: EdgeInsets.all(theme.spacing.l),
      decoration: BoxDecoration(
        color: theme.fillColorScheme.quaternary,
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
      ),
      child: Text.rich(
        TextSpan(
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
          children: textSpans,
        ),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(BuildContext context, String text) {
    final theme = AppFlowyTheme.of(context);
    final spans = <TextSpan>[];

    final parts = _splitPromptText(text);
    for (final part in parts) {
      if (part.startsWith('[') && part.endsWith(']')) {
        spans.add(
          TextSpan(
            text: part,
            style: TextStyle(color: theme.textColorScheme.purple),
          ),
        );
      } else {
        spans.add(TextSpan(text: part));
      }
    }

    return spans;
  }

  List<String> _splitPromptText(String text) {
    final regex = RegExp(r'(\[[^\[\]]*?\])');

    final result = <String>[];

    text.splitMapJoin(
      regex,
      onMatch: (match) {
        result.add(match.group(0)!);
        return '';
      },
      onNonMatch: (nonMatch) {
        result.add(nonMatch);
        return '';
      },
    );

    return result;
  }
}

class _PromptExample extends StatelessWidget {
  const _PromptExample({
    required this.prompt,
  });

  final AiPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      padding: EdgeInsets.all(theme.spacing.l),
      decoration: BoxDecoration(
        color: theme.fillColorScheme.quaternary,
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
      ),
      child: AIMarkdownText(
        markdown: prompt.example,
      ),
    );
  }
}

class _PromptSampleOutput extends StatelessWidget {
  const _PromptSampleOutput({
    required this.prompt,
  });

  final AiPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      padding: EdgeInsets.all(theme.spacing.l),
      decoration: BoxDecoration(
        color: theme.fillColorScheme.quaternary,
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
      ),
      child: AIMarkdownText(
        markdown: prompt.sampleResponse,
      ),
    );
  }
}
