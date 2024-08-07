import 'dart:math';

import 'package:appflowy/plugins/ai_chat/application/chat_file_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flowy_infra/platform_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/ai_message_bubble.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_related_question.dart';
import 'package:appflowy/plugins/ai_chat/presentation/user_message_bubble.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat;
import 'package:styled_widget/styled_widget.dart';

import 'application/chat_member_bloc.dart';
import 'application/chat_side_pannel_bloc.dart';
import 'presentation/chat_input/chat_input.dart';
import 'presentation/chat_popmenu.dart';
import 'presentation/chat_side_pannel.dart';
import 'presentation/chat_theme.dart';
import 'presentation/chat_user_invalid_message.dart';
import 'presentation/chat_welcome_page.dart';
import 'presentation/message/ai_text_message.dart';
import 'presentation/message/user_text_message.dart';

class AIChatUILayout {
  static EdgeInsets get chatPadding =>
      isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20);

  static EdgeInsets get welcomePagePadding => isMobile
      ? const EdgeInsets.symmetric(horizontal: 20)
      : const EdgeInsets.symmetric(horizontal: 50);

  static double get messageWidthRatio => 0.85;

  static EdgeInsets safeAreaInsets(BuildContext context) {
    final query = MediaQuery.of(context);
    return isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : const EdgeInsets.symmetric(horizontal: 50) +
            const EdgeInsets.only(bottom: 20);
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
    if (userProfile.authenticator == AuthenticatorPB.AppFlowyCloud) {
      return MultiBlocProvider(
        providers: [
          /// [ChatBloc] is used to handle chat messages including send/receive message
          ///
          BlocProvider(
            create: (_) => ChatBloc(
              view: view,
              userProfile: userProfile,
            )..add(const ChatEvent.initialLoad()),
          ),

          /// [ChatFileBloc] is used to handle file indexing as a chat context
          ///
          BlocProvider(
            create: (_) => ChatFileBloc(chatId: view.id.toString())
              ..add(const ChatFileEvent.initial()),
          ),

          /// [ChatInputStateBloc] is used to handle chat input text field state
          ///
          BlocProvider(
            create: (_) =>
                ChatInputStateBloc()..add(const ChatInputStateEvent.started()),
          ),
          BlocProvider(create: (_) => ChatSidePannelBloc(chatId: view.id)),
          BlocProvider(create: (_) => ChatMemberBloc()),
        ],
        child: BlocListener<ChatFileBloc, ChatFileState>(
          listenWhen: (previous, current) =>
              previous.indexFileIndicator != current.indexFileIndicator,
          listener: (context, state) {
            _handleIndexIndicator(state.indexFileIndicator, context);
          },
          child: BlocBuilder<ChatFileBloc, ChatFileState>(
            builder: (context, state) {
              return DropTarget(
                onDragDone: (DropDoneDetails detail) async {
                  if (state.supportChatWithFile) {
                    await showConfirmDialog(
                      context: context,
                      style: ConfirmPopupStyle.cancelAndOk,
                      title: LocaleKeys.chat_chatWithFilePrompt.tr(),
                      confirmLabel: LocaleKeys.button_confirm.tr(),
                      onConfirm: () {
                        for (final file in detail.files) {
                          context
                              .read<ChatFileBloc>()
                              .add(ChatFileEvent.newFile(file.path, file.name));
                        }
                      },
                      description: '',
                    );
                  }
                },
                child: _ChatContentPage(
                  view: view,
                  userProfile: userProfile,
                ),
              );
            },
          ),
        ),
      );
    }

    return Center(
      child: FlowyText(
        LocaleKeys.chat_unsupportedCloudPrompt.tr(),
        fontSize: 20,
      ),
    );
  }

  void _handleIndexIndicator(
    IndexFileIndicator? indicator,
    BuildContext context,
  ) {
    if (indicator != null) {
      indicator.when(
        finish: (fileName) {
          showSnackBarMessage(
            context,
            LocaleKeys.chat_indexFileSuccess.tr(args: [fileName]),
          );
        },
        indexing: (fileName) {
          showSnackBarMessage(
            context,
            LocaleKeys.chat_indexingFile.tr(args: [fileName]),
            duration: const Duration(seconds: 2),
          );
        },
        error: (err) {
          showSnackBarMessage(
            context,
            err,
          );
        },
      );
    }
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
    if (widget.userProfile.authenticator == AuthenticatorPB.AppFlowyCloud) {
      if (PlatformExtension.isDesktop) {
        return BlocSelector<ChatSidePannelBloc, ChatSidePannelState, bool>(
          selector: (state) => state.isShowPannel,
          builder: (context, isShowPannel) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double chatOffsetX = isShowPannel
                    ? 60
                    : (constraints.maxWidth > 784
                        ? (constraints.maxWidth - 784) / 2.0
                        : 60);

                final double width = isShowPannel
                    ? (constraints.maxWidth - chatOffsetX * 2) * 0.46
                    : min(constraints.maxWidth - chatOffsetX * 2, 784);

                final double sidePannelOffsetX = chatOffsetX + width;

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
                    if (isShowPannel)
                      buildChatSidePannel()
                          .positioned(
                            left: sidePannelOffsetX,
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

    return Center(
      child: FlowyText(
        LocaleKeys.chat_unsupportedCloudPrompt.tr(),
        fontSize: 20,
      ),
    );
  }

  Widget buildChatSidePannel() {
    if (PlatformExtension.isDesktop) {
      return BlocBuilder<ChatSidePannelBloc, ChatSidePannelState>(
        builder: (context, state) {
          if (state.metadata != null) {
            return const ChatSidePannel();
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else {
      // TODO(lucas): implement mobile chat side panel
      return const SizedBox.shrink();
    }
  }

  Widget buildChatWidget() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (blocContext, state) => Chat(
        key: ValueKey(widget.view.id),
        messages: state.messages,
        onSendPressed: (_) {
          // We use custom bottom widget for chat input, so
          // do not need to handle this event.
        },
        customBottomWidget: buildChatInput(blocContext),
        user: _user,
        theme: buildTheme(context),
        onEndReached: () async {
          if (state.hasMorePrevMessage &&
              state.loadingPreviousStatus != const LoadingState.loading()) {
            blocContext
                .read<ChatBloc>()
                .add(const ChatEvent.startLoadingPrevMessage());
          }
        },
        emptyState: BlocBuilder<ChatBloc, ChatState>(
          builder: (_, state) =>
              state.initialLoadingStatus == const LoadingState.finish()
                  ? Padding(
                      padding: AIChatUILayout.welcomePagePadding,
                      child: ChatWelcomePage(
                        onSelectedQuestion: (question) => blocContext
                            .read<ChatBloc>()
                            .add(ChatEvent.sendMessage(message: question)),
                      ),
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
            _buildAITextMessage(blocContext, textMessage),
        bubbleBuilder: (
          child, {
          required message,
          required nextMessageInGroup,
        }) {
          if (message.author.id == _user.id) {
            return ChatUserMessageBubble(
              message: message,
              child: child,
            );
          } else {
            return _buildAIBubble(message, blocContext, state, child);
          }
        },
      ),
    );
  }

  Widget _buildAITextMessage(BuildContext context, TextMessage message) {
    final isAuthor = message.author.id == _user.id;
    if (isAuthor) {
      return ChatTextMessageWidget(
        user: message.author,
        messageUserId: message.id,
        text: message.text,
      );
    } else {
      final stream = message.metadata?["$AnswerStream"];
      final questionId = message.metadata?["question"];
      final metadata = message.metadata?["metadata"] as String?;
      return ChatAITextMessageWidget(
        user: message.author,
        messageUserId: message.id,
        text: stream is AnswerStream ? stream : message.text,
        key: ValueKey(message.id),
        questionId: questionId,
        chatId: widget.view.id,
        metadata: metadata,
        onSelectedMetadata: (ChatMessageMetadata metadata) {
          context.read<ChatSidePannelBloc>().add(
                ChatSidePannelEvent.selectedMetadata(metadata),
              );
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

  Widget buildBubble(Message message, Widget child) {
    final isAuthor = message.author.id == _user.id;
    const borderRadius = BorderRadius.all(Radius.circular(6));
    final childWithPadding = isAuthor
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: child,
          )
        : Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          );

    // If the message is from the author, we will decorate it with a different color
    final decoratedChild = isAuthor
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: !isAuthor || message.type == types.MessageType.image
                  ? AFThemeExtension.of(context).tint1
                  : Theme.of(context).colorScheme.secondary,
            ),
            child: childWithPadding,
          )
        : childWithPadding;

    // If the message is from the author, no further actions are needed
    if (isAuthor) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: decoratedChild,
      );
    } else {
      if (isMobile) {
        return ChatPopupMenu(
          onAction: (action) {
            switch (action) {
              case ChatMessageAction.copy:
                if (message is TextMessage) {
                  Clipboard.setData(ClipboardData(text: message.text));
                  showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
                }
                break;
            }
          },
          builder: (context) =>
              ClipRRect(borderRadius: borderRadius, child: decoratedChild),
        );
      } else {
        // Show hover effect only on desktop
        return ClipRRect(
          borderRadius: borderRadius,
          child: ChatAIMessageHover(
            message: message,
            child: decoratedChild,
          ),
        );
      }
    }
  }

  Widget buildChatInput(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: AIChatUILayout.safeAreaInsets(context),
        child: BlocBuilder<ChatInputStateBloc, ChatInputStateState>(
          builder: (context, state) {
            // Show different hint text based on the AI type
            final aiType = state.aiType;
            final hintText = state.aiType.when(
              appflowyAI: () => LocaleKeys.chat_inputMessageHint.tr(),
              localAI: () => LocaleKeys.chat_inputLocalAIMessageHint.tr(),
            );

            return Column(
              children: [
                BlocSelector<ChatBloc, ChatState, bool>(
                  selector: (state) => state.canSendMessage,
                  builder: (context, canSendMessage) {
                    return ChatInput(
                      aiType: aiType,
                      chatId: widget.view.id,
                      onSendPressed: (message) {
                        context.read<ChatBloc>().add(
                              ChatEvent.sendMessage(
                                message: message.text,
                                metadata: message.metadata,
                              ),
                            );
                      },
                      isStreaming: !canSendMessage,
                      onStopStreaming: () {
                        context
                            .read<ChatBloc>()
                            .add(const ChatEvent.stopStream());
                      },
                      hintText: hintText,
                    );
                  },
                ),
                const VSpace(6),
                Opacity(
                  opacity: 0.6,
                  child: FlowyText(
                    LocaleKeys.chat_aiMistakePrompt.tr(),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

AFDefaultChatTheme buildTheme(BuildContext context) {
  return AFDefaultChatTheme(
    backgroundColor: AFThemeExtension.of(context).background,
    primaryColor: Theme.of(context).colorScheme.primary,
    secondaryColor: AFThemeExtension.of(context).tint1,
    receivedMessageDocumentIconColor: Theme.of(context).primaryColor,
    receivedMessageCaptionTextStyle: TextStyle(
      color: AFThemeExtension.of(context).textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    receivedMessageBodyTextStyle: TextStyle(
      color: AFThemeExtension.of(context).textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    receivedMessageLinkTitleTextStyle: TextStyle(
      color: AFThemeExtension.of(context).textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    receivedMessageBodyLinkTextStyle: const TextStyle(
      color: Colors.lightBlue,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    sentMessageBodyTextStyle: TextStyle(
      color: AFThemeExtension.of(context).textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    sentMessageBodyLinkTextStyle: const TextStyle(
      color: Colors.blue,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    inputElevation: 2,
  );
}
