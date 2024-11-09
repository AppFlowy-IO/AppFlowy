import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_loading.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:universal_platform/universal_platform.dart';

import 'ai_message_bubble.dart';
import 'ai_metadata.dart';

class ChatAIMessageWidget extends StatelessWidget {
  const ChatAIMessageWidget({
    super.key,
    required this.user,
    required this.messageUserId,
    required this.message,
    required this.stream,
    required this.questionId,
    required this.chatId,
    required this.refSourceJsonString,
    required this.onSelectedMetadata,
    this.isLastMessage = false,
  });

  final User user;
  final String messageUserId;

  final Message message;
  final AnswerStream? stream;
  final Int64? questionId;
  final String chatId;
  final String? refSourceJsonString;
  final void Function(ChatMessageRefSource metadata) onSelectedMetadata;
  final bool isLastMessage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatAIMessageBloc(
        message: stream ?? (message as TextMessage).text,
        refSourceJsonString: refSourceJsonString,
        chatId: chatId,
        questionId: questionId,
      ),
      child: BlocBuilder<ChatAIMessageBloc, ChatAIMessageState>(
        builder: (context, state) {
          return state.messageState.when(
            loading: () {
              return ChatAIMessageBubble(
                message: message,
                showActions: false,
                child: const ChatAILoading(),
              );
            },
            ready: () {
              return state.text.isEmpty
                  ? const SizedBox.shrink()
                  : ChatAIMessageBubble(
                      message: message,
                      isLastMessage: isLastMessage,
                      showActions: stream == null && state.text.isNotEmpty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AIMarkdownText(markdown: state.text),
                          if (state.sources.isNotEmpty)
                            AIMessageMetadata(
                              sources: state.sources,
                              onSelectedMetadata: onSelectedMetadata,
                            ),
                        ],
                      ),
                    );
            },
            onError: (err) {
              return StreamingError(
                onRetry: () {
                  context
                      .read<ChatAIMessageBloc>()
                      .add(const ChatAIMessageEvent.retry());
                },
              );
            },
            onAIResponseLimit: () {
              return const AIResponseLimitReachedError();
            },
          );
        },
      ),
    );
  }
}

class StreamingError extends StatefulWidget {
  const StreamingError({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  @override
  State<StreamingError> createState() => _StreamingErrorState();
}

class _StreamingErrorState extends State<StreamingError> {
  late final TapGestureRecognizer recognizer;

  @override
  void initState() {
    super.initState();
    recognizer = TapGestureRecognizer()..onTap = widget.onRetry;
  }

  @override
  void dispose() {
    recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 24.0),
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: Color(0x80FFE7EE),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        constraints: _errorConstraints(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlowySvg(
              FlowySvgs.warning_filled_s,
              blendMode: null,
            ),
            const HSpace(8.0),
            Flexible(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LocaleKeys.chat_aiServerUnavailable.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextSpan(
                      text: " ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextSpan(
                      text: LocaleKeys.chat_retry.tr(),
                      recognizer: recognizer,
                      mouseCursor: SystemMouseCursors.click,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AIResponseLimitReachedError extends StatelessWidget {
  const AIResponseLimitReachedError({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 16.0, bottom: 24.0),
        constraints: _errorConstraints(),
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: Color(0x80FFE7EE),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FlowySvg(
              FlowySvgs.warning_filled_s,
              blendMode: null,
            ),
            const HSpace(8.0),
            Flexible(
              child: FlowyText(
                LocaleKeys.sideBar_askOwnerToUpgradeToAIMax.tr(),
                lineHeight: 1.4,
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxConstraints _errorConstraints() {
  return UniversalPlatform.isDesktop
      ? const BoxConstraints(maxWidth: 480)
      : const BoxConstraints();
}
