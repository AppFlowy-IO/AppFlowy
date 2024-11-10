import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_related_question.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_message_bubble.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/other_user_message_bubble.dart';
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
import 'presentation/message/ai_text_message.dart';
import 'presentation/message/user_text_message.dart';

class AIChatUILayout {
  static double get messageWidthRatio => 0.94; // Chat adds extra 0.06

  static EdgeInsets safeAreaInsets(BuildContext context) {
    final query = MediaQuery.of(context);
    return UniversalPlatform.isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : const EdgeInsets.only(bottom: 16);
  }
}

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

class _ChatContentPage extends StatefulWidget {
  const _ChatContentPage({
    required this.view,
    required this.userProfile,
  });

  final UserProfilePB userProfile;
  final ViewPB view;

  @override
  State<_ChatContentPage> createState() => _ChatContentPageState();
}

class _ChatContentPageState extends State<_ChatContentPage> {
  late types.User _user;

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.userProfile.id.toString());
  }

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
      builder: (blocContext, state) => Chat(
        key: ValueKey(widget.view.id),
        messages: state.messages,
        dateHeaderBuilder: (_) => const SizedBox.shrink(),
        onSendPressed: (_) {
          // We use custom bottom widget for chat input, so
          // do not need to handle this event.
        },
        customBottomWidget: _buildBottom(blocContext),
        user: _user,
        theme: buildTheme(context),
        onEndReached: () async {
          if (state.hasMorePrevMessage &&
              state.loadingPreviousStatus.isFinish) {
            blocContext
                .read<ChatBloc>()
                .add(const ChatEvent.startLoadingPrevMessage());
          }
        },
        emptyState: BlocBuilder<ChatBloc, ChatState>(
          builder: (_, state) => state.initialLoadingStatus.isFinish
              ? ChatWelcomePage(
                  userProfile: widget.userProfile,
                  onSelectedQuestion: (question) => blocContext
                      .read<ChatBloc>()
                      .add(ChatEvent.sendMessage(message: question)),
                )
              : const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
        ),
        messageWidthRatio: AIChatUILayout.messageWidthRatio,
        textMessageBuilder: (
          textMessage, {
          required messageWidth,
          required showName,
        }) =>
            _buildTextMessage(blocContext, textMessage),
        bubbleBuilder: (
          child, {
          required message,
          required nextMessageInGroup,
        }) =>
            _buildBubble(blocContext, message, child, state),
      ),
    );
  }

  Widget _buildBubble(
    BuildContext blocContext,
    Message message,
    Widget child,
    ChatState state,
  ) {
    if (message.author.id == _user.id) {
      return ChatUserMessageBubble(
        message: message,
        child: child,
      );
    } else if (isOtherUserMessage(message)) {
      return OtherUserMessageBubble(
        message: message,
        child: child,
      );
    } else {
      return _buildAIBubble(message, blocContext, state, child);
    }
  }

  Widget _buildTextMessage(BuildContext context, TextMessage message) {
    if (message.author.id == _user.id) {
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
      return ChatAIMessageWidget(
        user: message.author,
        messageUserId: message.id,
        message: stream is AnswerStream ? stream : message.text,
        key: ValueKey(message.id),
        questionId: questionId,
        chatId: widget.view.id,
        refSourceJsonString: refSourceJsonString,
        onSelectedMetadata: (ChatMessageRefSource metadata) {
          context
              .read<ChatSidePanelBloc>()
              .add(ChatSidePanelEvent.selectedMetadata(metadata));
        },
      );
    }
  }

  Widget _buildAIBubble(
    Message message,
    BuildContext blocContext,
    ChatState state,
    Widget child,
  ) {
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
        onQuestionSelected: (question) {
          blocContext
              .read<ChatBloc>()
              .add(ChatEvent.sendMessage(message: question));
          blocContext
              .read<ChatBloc>()
              .add(const ChatEvent.clearReleatedQuestion());
        },
        chatId: widget.view.id,
        relatedQuestions: state.relatedQuestions,
      );
    }

    return ChatAIMessageBubble(
      message: message,
      customMessageType: messageType,
      child: child,
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Padding(
      padding: AIChatUILayout.safeAreaInsets(context),
      child: BlocSelector<ChatBloc, ChatState, bool>(
        selector: (state) => state.canSendMessage,
        builder: (context, canSendMessage) {
          return UniversalPlatform.isDesktop
              ? DesktopAIPromptInput(
                  chatId: widget.view.id,
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
                  chatId: widget.view.id,
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
}

AFDefaultChatTheme buildTheme(BuildContext context) {
  return AFDefaultChatTheme(
    primaryColor: Theme.of(context).colorScheme.primary,
    secondaryColor: AFThemeExtension.of(context).tint1,
  );
}
