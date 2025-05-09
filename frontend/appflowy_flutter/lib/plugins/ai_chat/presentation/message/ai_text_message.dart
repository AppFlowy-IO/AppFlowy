import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

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
    required this.onStopStream,
    this.onSelectedMetadata,
    this.onRegenerate,
    this.onChangeFormat,
    this.onChangeModel,
    this.isLastMessage = false,
    this.isStreaming = false,
    this.isSelectingMessages = false,
    this.enableAnimation = true,
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
  final void Function() onStopStream;
  final void Function(PredefinedFormat)? onChangeFormat;
  final void Function(AIModelPB)? onChangeModel;
  final bool isStreaming;
  final bool isLastMessage;
  final bool isSelectingMessages;
  final bool enableAnimation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatAIMessageBloc(
        message: stream ?? (message as TextMessage).text,
        refSourceJsonString: refSourceJsonString,
        chatId: chatId,
        questionId: questionId,
      ),
      child: BlocConsumer<ChatAIMessageBloc, ChatAIMessageState>(
        listenWhen: (previous, current) =>
            previous.messageState != current.messageState,
        listener: (context, state) => _handleMessageState(state, context),
        builder: (context, blocState) {
          final loadingText = blocState.progress?.step ??
              LocaleKeys.chat_generatingResponse.tr();

          return Padding(
            padding: AIChatUILayout.messageMargin,
            child: blocState.messageState.when(
              loading: () => ChatAIMessageBubble(
                message: message,
                showActions: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AILoadingIndicator(text: loadingText),
                ),
              ),
              ready: () {
                return blocState.text.isEmpty
                    ? _LoadingMessage(
                        message: message,
                        loadingText: loadingText,
                      )
                    : _NonEmptyMessage(
                        user: user,
                        messageUserId: messageUserId,
                        message: message,
                        stream: stream,
                        questionId: questionId,
                        chatId: chatId,
                        refSourceJsonString: refSourceJsonString,
                        onStopStream: onStopStream,
                        onSelectedMetadata: onSelectedMetadata,
                        onRegenerate: onRegenerate,
                        onChangeFormat: onChangeFormat,
                        onChangeModel: onChangeModel,
                        isLastMessage: isLastMessage,
                        isStreaming: isStreaming,
                        isSelectingMessages: isSelectingMessages,
                        enableAnimation: enableAnimation,
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
              onAIImageResponseLimit: () {
                return ChatErrorMessageWidget(
                  errorMessage: LocaleKeys.sideBar_purchaseAIMax.tr(),
                );
              },
              onAIMaxRequired: (message) {
                return ChatErrorMessageWidget(
                  errorMessage: message,
                );
              },
              onInitializingLocalAI: () {
                onStopStream();

                return ChatErrorMessageWidget(
                  errorMessage:
                      LocaleKeys.settings_aiPage_keys_localAIInitializing.tr(),
                );
              },
              aiFollowUp: (followUpData) {
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  void _handleMessageState(ChatAIMessageState state, BuildContext context) {
    if (state.stream?.error?.isEmpty != false) {
      state.messageState.maybeMap(
        aiFollowUp: (messageState) {
          context
              .read<ChatBloc>()
              .add(ChatEvent.onAIFollowUp(messageState.followUpData));
        },
        orElse: () {
          // do nothing
        },
      );

      return;
    }
    context.read<ChatBloc>().add(ChatEvent.deleteMessage(message));
  }
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage({
    required this.message,
    required this.loadingText,
  });

  final Message message;
  final String loadingText;

  @override
  Widget build(BuildContext context) {
    return ChatAIMessageBubble(
      message: message,
      showActions: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: AILoadingIndicator(text: loadingText),
      ),
    );
  }
}

class _NonEmptyMessage extends StatelessWidget {
  const _NonEmptyMessage({
    required this.user,
    required this.messageUserId,
    required this.message,
    required this.stream,
    required this.questionId,
    required this.chatId,
    required this.refSourceJsonString,
    required this.onStopStream,
    this.onSelectedMetadata,
    this.onRegenerate,
    this.onChangeFormat,
    this.onChangeModel,
    this.isLastMessage = false,
    this.isStreaming = false,
    this.isSelectingMessages = false,
    this.enableAnimation = true,
  });

  final User user;
  final String messageUserId;

  final Message message;
  final AnswerStream? stream;
  final Int64? questionId;
  final String chatId;
  final String? refSourceJsonString;
  final ValueChanged<ChatMessageRefSource>? onSelectedMetadata;
  final VoidCallback? onRegenerate;
  final VoidCallback onStopStream;
  final ValueChanged<PredefinedFormat>? onChangeFormat;
  final ValueChanged<AIModelPB>? onChangeModel;
  final bool isStreaming;
  final bool isLastMessage;
  final bool isSelectingMessages;
  final bool enableAnimation;

  @override
  Widget build(BuildContext context) {
    final state = context.read<ChatAIMessageBloc>().state;
    final showActions = stream == null && state.text.isNotEmpty && !isStreaming;
    return ChatAIMessageBubble(
      message: message,
      isLastMessage: isLastMessage,
      showActions: showActions,
      isSelectingMessages: isSelectingMessages,
      onRegenerate: onRegenerate,
      onChangeFormat: onChangeFormat,
      onChangeModel: onChangeModel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AIMarkdownText(
            markdown: state.text,
            withAnimation: enableAnimation && stream != null,
          ),
          if (state.sources.isNotEmpty)
            SelectionContainer.disabled(
              child: AIMessageMetadata(
                sources: state.sources,
                onSelectedMetadata: onSelectedMetadata,
              ),
            ),
          if (state.sources.isNotEmpty && !isLastMessage) const VSpace(8.0),
        ],
      ),
    );
  }
}
