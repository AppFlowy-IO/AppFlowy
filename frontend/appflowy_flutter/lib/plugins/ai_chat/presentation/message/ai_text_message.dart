import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_loading.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatAITextMessageWidget extends StatelessWidget {
  const ChatAITextMessageWidget({
    super.key,
    required this.user,
    required this.messageUserId,
    required this.text,
    required this.questionId,
    required this.chatId,
    required this.metadata,
  });

  final User user;
  final String messageUserId;
  final dynamic text;
  final Int64? questionId;
  final String chatId;
  final String? metadata;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatAIMessageBloc(
        message: text,
        metadata: metadata,
        chatId: chatId,
        questionId: questionId,
      )..add(const ChatAIMessageEvent.initial()),
      child: BlocBuilder<ChatAIMessageBloc, ChatAIMessageState>(
        builder: (context, state) {
          return state.messageState.when(
            onError: (err) {
              return StreamingError(
                onRetryPressed: () {
                  context.read<ChatAIMessageBloc>().add(
                        const ChatAIMessageEvent.retry(),
                      );
                },
              );
            },
            onAIResponseLimit: () {
              return FlowyText(
                LocaleKeys.sideBar_askOwnerToUpgradeToAIMax.tr(),
                maxLines: 10,
                lineHeight: 1.5,
              );
            },
            ready: () {
              if (state.text.isEmpty) {
                return const ChatAILoading();
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AIMarkdownText(markdown: state.text),
                    AIMessageMetadata(metadata: state.metadata),
                  ],
                );
              }
            },
            loading: () {
              return const ChatAILoading();
            },
          );
        },
      ),
    );
  }
}

class StreamingError extends StatelessWidget {
  const StreamingError({
    required this.onRetryPressed,
    super.key,
  });

  final void Function() onRetryPressed;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 4, thickness: 1),
        const VSpace(16),
        Center(
          child: Column(
            children: [
              _aiUnvaliable(),
              const VSpace(10),
              _retryButton(),
            ],
          ),
        ),
      ],
    );
  }

  FlowyButton _retryButton() {
    return FlowyButton(
      radius: BorderRadius.circular(20),
      useIntrinsicWidth: true,
      text: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: FlowyText(
          LocaleKeys.chat_regenerateAnswer.tr(),
          fontSize: 14,
        ),
      ),
      onTap: onRetryPressed,
      iconPadding: 0,
      leftIcon: const Icon(
        Icons.refresh,
        size: 20,
      ),
    );
  }

  Padding _aiUnvaliable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FlowyText(
        LocaleKeys.chat_aiServerUnavailable.tr(),
        fontSize: 14,
      ),
    );
  }
}

class AIMessageMetadata extends StatelessWidget {
  const AIMessageMetadata({required this.metadata, super.key});

  final List<ChatMessageMetadata> metadata;
  @override
  Widget build(BuildContext context) {
    final title = metadata.length == 1
        ? LocaleKeys.chat_referenceSource.tr(args: [metadata.length.toString()])
        : LocaleKeys.chat_referenceSources
            .tr(args: [metadata.length.toString()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metadata.isNotEmpty)
          Opacity(
            opacity: 0.5,
            child: FlowyText(title, fontSize: 12),
          ),
        const VSpace(6),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: metadata
              .map(
                (m) => SizedBox(
                  height: 24,
                  child: FlowyButton(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    useIntrinsicWidth: true,
                    radius: BorderRadius.circular(6),
                    text: FlowyText(
                      m.source,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
