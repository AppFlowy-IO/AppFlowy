import 'package:appflowy/ai/widgets/loading_indicator.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:universal_platform/universal_platform.dart';

import '../layout_define.dart';
import 'ai_markdown_text.dart';
import 'ai_message_bubble.dart';
import 'ai_metadata.dart';
import 'error_text_message.dart';

/// [ChatAIMessageWidget] includes both the text of the AI response as well as
/// the avatar, decorations and hover effects that are also rendered. This is
/// different from [ChatUserMessageWidget] which only contains the message and
/// has to be separately wrapped with a bubble since the hover effects need to
/// know the current streaming status of the message.
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
    this.onSelectedMetadata,
    this.onRegenerate,
    this.onChangeFormat,
    this.isLastMessage = false,
    this.isStreaming = false,
  });

  final User user;
  final String messageUserId;

  final Message message;
  final AnswerStream? stream;
  final Int64? questionId;
  final String chatId;
  final String? refSourceJsonString;
  final void Function(ChatMessageRefSource metadata)? onSelectedMetadata;
  final void Function()? onRegenerate;
  final void Function(PredefinedFormat)? onChangeFormat;
  final bool isStreaming;
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
          final loadingText =
              state.progress?.step ?? LocaleKeys.chat_generatingResponse.tr();

          return BlocListener<ChatBloc, ChatState>(
            listenWhen: (previous, current) =>
                previous.clearErrorMessages != current.clearErrorMessages,
            listener: (context, chatState) {
              if (state.stream?.error?.isEmpty != false) {
                return;
              }
              context.read<ChatBloc>().add(ChatEvent.deleteMessage(message));
            },
            child: Padding(
              padding: AIChatUILayout.messageMargin,
              child: state.messageState.when(
                loading: () => ChatAIMessageBubble(
                  message: message,
                  showActions: false,
                  child: AILoadingIndicator(text: loadingText),
                ),
                ready: () {
                  return state.text.isEmpty
                      ? ChatAIMessageBubble(
                          message: message,
                          showActions: false,
                          child: AILoadingIndicator(text: loadingText),
                        )
                      : ChatAIMessageBubble(
                          message: message,
                          isLastMessage: isLastMessage,
                          showActions: stream == null &&
                              state.text.isNotEmpty &&
                              !isStreaming,
                          onRegenerate: onRegenerate,
                          onChangeFormat: onChangeFormat,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IgnorePointer(
                                ignoring: UniversalPlatform.isMobile,
                                child: AIMarkdownText(markdown: state.text),
                              ),
                              if (state.sources.isNotEmpty)
                                AIMessageMetadata(
                                  sources: state.sources,
                                  onSelectedMetadata: onSelectedMetadata,
                                ),
                              if (state.sources.isNotEmpty && !isLastMessage)
                                const VSpace(8.0),
                            ],
                          ),
                        );
                },
                onError: (error) {
                  return ChatErrorMessageWidget(
                    errorMessage: LocaleKeys.chat_aiServerUnavailable.tr(),
                  );
                },
                onAIResponseLimit: () {
                  return ChatErrorMessageWidget(
                    errorMessage:
                        LocaleKeys.sideBar_askOwnerToUpgradeToAIMax.tr(),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
