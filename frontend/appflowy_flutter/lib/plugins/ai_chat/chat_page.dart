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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'presentation/chat_input.dart';
import 'presentation/chat_popmenu.dart';
import 'presentation/chat_theme.dart';
import 'presentation/chat_user_invalid_message.dart';
import 'presentation/chat_welcome_page.dart';
import 'presentation/message/ai_text_message.dart';
import 'presentation/message/user_text_message.dart';

class AIChatUILayout {
  static EdgeInsets get chatPadding =>
      isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 70);

  static EdgeInsets get welcomePagePadding => isMobile
      ? const EdgeInsets.symmetric(horizontal: 20)
      : const EdgeInsets.symmetric(horizontal: 100);

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
        : const EdgeInsets.symmetric(horizontal: 70);
  }
}

class AIChatPage extends StatefulWidget {
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
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  late types.User _user;

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.userProfile.id.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userProfile.authenticator == AuthenticatorPB.AppFlowyCloud) {
      return buildChatWidget();
    } else {
      return Center(
        child: FlowyText(
          LocaleKeys.chat_unsupportedCloudPrompt.tr(),
          fontSize: 20,
        ),
      );
    }
  }

  Widget buildChatWidget() {
    return SizedBox.expand(
      child: Padding(
        padding: AIChatUILayout.chatPadding,
        child: BlocProvider(
          create: (context) => ChatBloc(
            view: widget.view,
            userProfile: widget.userProfile,
          )..add(const ChatEvent.initialLoad()),
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (blocContext, state) {
              return Chat(
                messages: state.messages,
                onAttachmentPressed: () {},
                onSendPressed: (types.PartialText message) {
                  // We use custom bottom widget for chat input, so
                  // do not need to handle this event.
                },
                customBottomWidget: buildChatInput(blocContext),
                user: _user,
                theme: buildTheme(context),
                onEndReached: () async {
                  if (state.hasMorePrevMessage &&
                      state.loadingPreviousStatus !=
                          const LoadingState.loading()) {
                    blocContext
                        .read<ChatBloc>()
                        .add(const ChatEvent.startLoadingPrevMessage());
                  }
                },
                emptyState: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return state.initialLoadingStatus ==
                            const LoadingState.finish()
                        ? Padding(
                            padding: AIChatUILayout.welcomePagePadding,
                            child: ChatWelcomePage(
                              onSelectedQuestion: (question) {
                                blocContext
                                    .read<ChatBloc>()
                                    .add(ChatEvent.sendMessage(question));
                              },
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator.adaptive(),
                          );
                  },
                ),
                messageWidthRatio: AIChatUILayout.messageWidthRatio,
                textMessageBuilder: (
                  textMessage, {
                  required messageWidth,
                  required showName,
                }) {
                  return _buildAITextMessage(blocContext, textMessage);
                },
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
              );
            },
          ),
        ),
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
      return ChatAITextMessageWidget(
        user: message.author,
        messageUserId: message.id,
        text: stream is AnswerStream ? stream : message.text,
        key: ValueKey(message.id),
        questionId: questionId,
        chatId: widget.view.id,
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
          blocContext.read<ChatBloc>().add(ChatEvent.sendMessage(question));
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
        child: Column(
          children: [
            BlocSelector<ChatBloc, ChatState, LoadingState>(
              selector: (state) => state.streamingStatus,
              builder: (context, state) {
                return ChatInput(
                  chatId: widget.view.id,
                  onSendPressed: (message) =>
                      onSendPressed(context, message.text),
                  isStreaming: state != const LoadingState.finish(),
                  onStopStreaming: () {
                    context.read<ChatBloc>().add(const ChatEvent.stopStream());
                  },
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
        ),
      ),
    );
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

  void onSendPressed(BuildContext context, String message) {
    context.read<ChatBloc>().add(ChatEvent.sendMessage(message));
  }
}
