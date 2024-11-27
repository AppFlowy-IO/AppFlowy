import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/ask_ai_action_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AskAiInputContent extends StatelessWidget {
  const AskAiInputContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AskAIActionBloc, AskAIState>(
      builder: (context, state) {
        return Card(
          elevation: 5,
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowyText.medium(
                  state.action.name,
                  fontSize: 14,
                ),
                const VSpace(16),
                state.loading
                    ? _buildLoadingWidget(context)
                    : _buildResultWidget(context, state),
                const VSpace(16),
                const AskAIFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultWidget(BuildContext context, AskAIState state) {
    return Flexible(
      child: AIMarkdownText(
        markdown: state.result,
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

class AskAIFooter extends StatelessWidget {
  const AskAIFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedRoundedButton(
          text: LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
          onTap: () =>
              context.read<AskAIActionBloc>().add(const AskAIEvent.rewrite()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_replace.tr(),
          onTap: () =>
              context.read<AskAIActionBloc>().add(const AskAIEvent.replace()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_insertBelow.tr(),
          onTap: () => context
              .read<AskAIActionBloc>()
              .add(const AskAIEvent.insertBelow()),
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_cancel.tr(),
          onTap: () =>
              context.read<AskAIActionBloc>().add(const AskAIEvent.cancel()),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerRight,
            child: Text(
              LocaleKeys.document_plugins_warning.tr(),
              style: TextStyle(color: Theme.of(context).hintColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
