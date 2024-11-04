import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_related_question.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/user_message_bubble.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat;
import 'package:styled_widget/styled_widget.dart';
import 'package:universal_platform/universal_platform.dart';

import 'application/chat_member_bloc.dart';
import 'application/chat_side_panel_bloc.dart';
import 'presentation/chat_input/desktop_ai_prompt_input.dart';
import 'presentation/chat_input/mobile_ai_prompt_input.dart';
import 'presentation/chat_side_panel.dart';
import 'presentation/chat_theme.dart';
import 'presentation/chat_user_invalid_message.dart';
import 'presentation/chat_welcome_page.dart';
import 'presentation/layout_define.dart';
import 'presentation/message/ai_text_message.dart';
import 'presentation/message/user_text_message.dart';

class AIChatPage extends StatelessWidget {
  const AIChatPage({
    super.key,
    required this.view,
    required this.onDeleted,
    required this.userProfile,
  });

  final ViewPB view;
  final VoidCallback onDeleted;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    if (userProfile.authenticator != AuthenticatorPB.AppFlowyCloud) {
      return Center(
        child: FlowyText(
          LocaleKeys.chat_unsupportedCloudPrompt.tr(),
          fontSize: 20,
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        /// [ChatBloc] is used to handle chat messages including send/receive message
        BlocProvider(
          create: (_) => ChatBloc(
            view: view,
            userProfile: userProfile,
          )..add(const ChatEvent.initialLoad()),
        ),

        /// [AIPromptInputBloc] is used to handle the user prompt
        BlocProvider(create: (_) => AIPromptInputBloc()),
        BlocProvider(create: (_) => ChatSidePanelBloc(chatId: view.id)),
        BlocProvider(create: (_) => ChatMemberBloc()),
      ],
      child: DropTarget(
        onDragDone: (DropDoneDetails detail) async {
          if (context.read<AIPromptInputBloc>().state.supportChatWithFile) {
            for (final file in detail.files) {
              context
                  .read<AIPromptInputBloc>()
                  .add(AIPromptInputEvent.newFile(file.path, file.name));
            }
          }
        },
        child: _ChatContentPage(
          view: view,
          userProfile: userProfile,
        ),
      ),
    );
  }
}

class _ChatContentPage extends StatelessWidget {
  const _ChatContentPage({
    required this.view,
    required this.userProfile,
  });

  final UserProfilePB userProfile;
  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isDesktop) {
      return BlocSelector<ChatSidePanelBloc, ChatSidePanelState, bool>(
        selector: (state) => state.isShowPanel,
        builder: (context, isShowPanel) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double chatOffsetX = isShowPanel
                  ? 60
                  : (constraints.maxWidth > 784
                      ? (constraints.maxWidth - 784) / 2.0
                      : 60);

              final double width = isShowPanel
                  ? (constraints.maxWidth - chatOffsetX * 2) * 0.46
                  : min(constraints.maxWidth - chatOffsetX * 2, 784);

              final double sidePanelOffsetX = chatOffsetX + width;

              return Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  buildChatWidget()
                      .constrained(width: width)
                      .positioned(
                        top: 0,
                        bottom: 0,
                        left: chatOffsetX,
                        animate: true,
                      )
                      .animate(
                        const Duration(milliseconds: 200),
                        Curves.easeOut,
                      ),
                  if (isShowPanel)
                    buildChatSidePanel()
                        .positioned(
                          left: sidePanelOffsetX,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          animate: true,
                        )
                        .animate(
                          const Duration(milliseconds: 200),
                          Curves.easeOut,
                        ),
                ],
              );
            },
          );
        },
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 784),
              child: buildChatWidget(),
            ),
          ),
        ],
      );
    }
  }

  Widget buildChatSidePanel() {
    return BlocBuilder<ChatSidePanelBloc, ChatSidePanelState>(
      builder: (context, state) {
        if (state.metadata == null) {
          return const SizedBox.shrink();
        }
        return const ChatSidePanel();
      },
    );
  }

  Widget buildChatWidget() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (_, state) => state.initialLoadingStatus.isFinish
                ? Chat(
                    messages: state.messages,
                    dateHeaderBuilder: (_) => const SizedBox.shrink(),
                    onSendPressed: (_) {
                      // We use custom bottom widget for chat input, so
                      // do not need to handle this event.
                    },
                    customBottomWidget: _buildBottom(context),
                    user: types.User(id: userProfile.id.toString()),
                    theme: _buildTheme(context),
                    onEndReached: () async {
                      if (state.hasMorePrevMessage &&
                          state.loadingPreviousStatus.isFinish) {
                        context
                            .read<ChatBloc>()
                            .add(const ChatEvent.startLoadingPrevMessage());
                      }
                    },
                    emptyState: ChatWelcomePage(
                      userProfile: userProfile,
                      onSelectedQuestion: (question) => context
                          .read<ChatBloc>()
                          .add(ChatEvent.sendMessage(message: question)),
                    ),
                    messageWidthRatio: AIChatUILayout.messageWidthRatio,
                    textMessageBuilder: (
                      textMessage, {
                      required messageWidth,
                      required showName,
                    }) =>
                        _buildTextMessage(context, textMessage, state),
                    bubbleBuilder: (
                      child, {
                      required message,
                      required nextMessageInGroup,
                    }) =>
                        _buildBubble(context, message, child),
                  )
                : const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTextMessage(
    BuildContext context,
    TextMessage message,
    ChatState state,
  ) {
    if (message.author.id == userProfile.id.toString()) {
      final stream = message.metadata?["$QuestionStream"];
      return ChatUserMessageWidget(
        key: ValueKey(message.id),
        user: message.author,
        message: stream is QuestionStream ? stream : message.text,
      );
    } else if (isOtherUserMessage(message)) {
      final stream = message.metadata?["$QuestionStream"];
      return ChatUserMessageWidget(
        key: ValueKey(message.id),
        user: message.author,
        message: stream is QuestionStream ? stream : message.text,
      );
    } else {
      final stream = message.metadata?["$AnswerStream"];
      final questionId = message.metadata?[messageQuestionIdKey];
      final refSourceJsonString =
          message.metadata?[messageRefSourceJsonStringKey] as String?;

      final messageType = onetimeMessageTypeFromMeta(
        message.metadata,
      );

      if (messageType == OnetimeShotType.invalidSendMesssage) {
        return ChatInvalidUserMessage(
          message: message,
        );
      }

      if (messageType == OnetimeShotType.relatedQuestion) {
        return RelatedQuestionList(
          relatedQuestions: state.relatedQuestions,
          onQuestionSelected: (question) {
            final bloc = context.read<ChatBloc>();
            bloc
              ..add(ChatEvent.sendMessage(message: question))
              ..add(const ChatEvent.clearRelatedQuestions());
          },
        );
      }

      return BlocSelector<ChatBloc, ChatState, bool>(
        selector: (state) {
          final messages = state.messages.where((e) {
            final oneTimeMessageType = onetimeMessageTypeFromMeta(e.metadata);
            if (oneTimeMessageType == null) {
              return true;
            }
            if (oneTimeMessageType
                case OnetimeShotType.relatedQuestion ||
                    OnetimeShotType.sendingMessage ||
                    OnetimeShotType.invalidSendMesssage) {
              return false;
            }
            return true;
          });
          return messages.isEmpty ? false : messages.first.id == message.id;
        },
        builder: (context, isLastMessage) {
          return ChatAIMessageWidget(
            key: ValueKey(message.id),
            user: message.author,
            messageUserId: message.id,
            message: message,
            stream: stream is AnswerStream ? stream : null,
            questionId: questionId,
            chatId: view.id,
            refSourceJsonString: refSourceJsonString,
            isLastMessage: isLastMessage,
            onSelectedMetadata: (metadata) {
              context
                  .read<ChatSidePanelBloc>()
                  .add(ChatSidePanelEvent.selectedMetadata(metadata));
            },
          );
        },
      );
    }
  }

  Widget _buildBubble(
    BuildContext context,
    Message message,
    Widget child,
  ) {
    if (message.author.id == userProfile.id.toString()) {
      return ChatUserMessageBubble(
        message: message,
        child: child,
      );
    } else if (isOtherUserMessage(message)) {
      return ChatUserMessageBubble(
        message: message,
        isCurrentUser: false,
        child: child,
      );
    } else {
      return child;
    }
  }

  Widget _buildBottom(BuildContext context) {
    return Padding(
      padding: AIChatUILayout.safeAreaInsets(context),
      child: BlocSelector<ChatBloc, ChatState, bool>(
        selector: (state) => state.canSendMessage,
        builder: (context, canSendMessage) {
          return UniversalPlatform.isDesktop
              ? DesktopAIPromptInput(
                  chatId: view.id,
                  indicateFocus: true,
                  onSubmitted: (message) {
                    context.read<ChatBloc>().add(
                          ChatEvent.sendMessage(
                            message: message.text,
                            metadata: message.metadata,
                          ),
                        );
                  },
                  isStreaming: !canSendMessage,
                  onStopStreaming: () {
                    context.read<ChatBloc>().add(const ChatEvent.stopStream());
                  },
                )
              : MobileAIPromptInput(
                  chatId: view.id,
                  onSubmitted: (message) {
                    context.read<ChatBloc>().add(
                          ChatEvent.sendMessage(
                            message: message.text,
                            metadata: message.metadata,
                          ),
                        );
                  },
                  isStreaming: !canSendMessage,
                  onStopStreaming: () {
                    context.read<ChatBloc>().add(const ChatEvent.stopStream());
                  },
                );
        },
      ),
    );
  }

  AFDefaultChatTheme _buildTheme(BuildContext context) {
    return AFDefaultChatTheme(
      primaryColor: Theme.of(context).colorScheme.primary,
      secondaryColor: AFThemeExtension.of(context).tint1,
    );
  }
}
