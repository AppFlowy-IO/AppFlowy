import 'dart:io';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_message_selector_banner.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart'
    hide ChatAnimatedListReversed;
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import 'application/chat_bloc.dart';
import 'application/chat_entity.dart';
import 'application/chat_member_bloc.dart';
import 'application/chat_select_message_bloc.dart';
import 'application/chat_message_stream.dart';
import 'presentation/animated_chat_list.dart';
import 'presentation/chat_input/mobile_chat_input.dart';
import 'presentation/chat_related_question.dart';
import 'presentation/chat_welcome_page.dart';
import 'presentation/layout_define.dart';
import 'presentation/message/ai_text_message.dart';
import 'presentation/message/error_text_message.dart';
import 'presentation/message/message_util.dart';
import 'presentation/message/user_text_message.dart';
import 'presentation/scroll_to_bottom.dart';

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
    // if (userProfile.authenticator != AuthTypePB.Server) {
    //   return Center(
    //     child: FlowyText(
    //       LocaleKeys.chat_unsupportedCloudPrompt.tr(),
    //       fontSize: 20,
    //     ),
    //   );
    // }

    return MultiBlocProvider(
      providers: [
        /// [ChatBloc] is used to handle chat messages including send/receive message
        BlocProvider(
          create: (_) => ChatBloc(
            chatId: view.id,
            userId: userProfile.id.toString(),
          ),
        ),

        /// [AIPromptInputBloc] is used to handle the user prompt
        BlocProvider(
          create: (_) => AIPromptInputBloc(
            objectId: view.id,
            predefinedFormat: PredefinedFormat(
              imageFormat: ImageFormat.text,
              textFormat: TextFormat.bulletList,
            ),
          ),
        ),
        BlocProvider(create: (_) => ChatMemberBloc()),
      ],
      child: Builder(
        builder: (context) {
          return DropTarget(
            onDragDone: (DropDoneDetails detail) async {
              if (context.read<AIPromptInputBloc>().state.supportChatWithFile) {
                for (final file in detail.files) {
                  context
                      .read<AIPromptInputBloc>()
                      .add(AIPromptInputEvent.attachFile(file.path, file.name));
                }
              }
            },
            child: FocusScope(
              onKeyEvent: (focusNode, event) {
                if (event is! KeyUpEvent) {
                  return KeyEventResult.ignored;
                }

                if (event.logicalKey == LogicalKeyboardKey.escape ||
                    event.logicalKey == LogicalKeyboardKey.keyC &&
                        HardwareKeyboard.instance.isControlPressed) {
                  final chatBloc = context.read<ChatBloc>();
                  if (chatBloc.state.promptResponseState !=
                      PromptResponseState.ready) {
                    chatBloc.add(ChatEvent.stopStream());
                    return KeyEventResult.handled;
                  }
                }

                return KeyEventResult.ignored;
              },
              child: _ChatContentPage(
                view: view,
                userProfile: userProfile,
              ),
            ),
          );
        },
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
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return switch (state.loadingState) {
          LoadChatMessageStatus.ready => Column(
              children: [
                ChatMessageSelectorBanner(
                  view: view,
                  allMessages: context.read<ChatBloc>().chatController.messages,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _wrapConstraints(
                      SelectionArea(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: Chat(
                            chatController:
                                context.read<ChatBloc>().chatController,
                            user: User(id: userProfile.id.toString()),
                            darkTheme:
                                ChatTheme.fromThemeData(Theme.of(context)),
                            theme: ChatTheme.fromThemeData(Theme.of(context)),
                            builders: Builders(
                              inputBuilder: (_) => const SizedBox.shrink(),
                              textMessageBuilder: _buildTextMessage,
                              chatMessageBuilder: _buildChatMessage,
                              scrollToBottomBuilder: _buildScrollToBottom,
                              chatAnimatedListBuilder: _buildChatAnimatedList,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _wrapConstraints(
                  _Input(view: view),
                ),
              ],
            ),
          _ => const Center(child: CircularProgressIndicator.adaptive()),
        };
      },
    );
  }

  Widget _wrapConstraints(Widget child) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 784),
      margin: UniversalPlatform.isDesktop
          ? const EdgeInsets.symmetric(horizontal: 60.0)
          : null,
      child: child,
    );
  }

  Widget _buildTextMessage(
    BuildContext context,
    TextMessage message,
  ) {
    final messageType = onetimeMessageTypeFromMeta(
      message.metadata,
    );

    if (messageType == OnetimeShotType.error) {
      return ChatErrorMessageWidget(
        errorMessage: message.metadata?[errorMessageTextKey] ?? "",
      );
    }

    if (messageType == OnetimeShotType.relatedQuestion) {
      return RelatedQuestionList(
        relatedQuestions: message.metadata!['questions'],
        onQuestionSelected: (question) {
          final bloc = context.read<AIPromptInputBloc>();
          final showPredefinedFormats = bloc.state.showPredefinedFormats;
          final predefinedFormat = bloc.state.predefinedFormat;

          context.read<ChatBloc>().add(
                ChatEvent.sendMessage(
                  message: question,
                  format: showPredefinedFormats ? predefinedFormat : null,
                ),
              );
        },
      );
    }

    if (message.author.id == userProfile.id.toString() ||
        isOtherUserMessage(message)) {
      return ChatUserMessageWidget(
        user: message.author,
        message: message,
      );
    }

    final stream = message.metadata?["$AnswerStream"];
    final questionId = message.metadata?[messageQuestionIdKey];
    final refSourceJsonString =
        message.metadata?[messageRefSourceJsonStringKey] as String?;

    return BlocSelector<ChatSelectMessageBloc, ChatSelectMessageState, bool>(
      selector: (state) => state.isSelectingMessages,
      builder: (context, isSelectingMessages) {
        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final chatController = context.read<ChatBloc>().chatController;
            final messages = chatController.messages
                .where((e) => onetimeMessageTypeFromMeta(e.metadata) == null);
            final isLastMessage =
                messages.isEmpty ? false : messages.last.id == message.id;
            return ChatAIMessageWidget(
              user: message.author,
              messageUserId: message.id,
              message: message,
              stream: stream is AnswerStream ? stream : null,
              questionId: questionId,
              chatId: view.id,
              refSourceJsonString: refSourceJsonString,
              isStreaming:
                  state.promptResponseState != PromptResponseState.ready,
              isLastMessage: isLastMessage,
              isSelectingMessages: isSelectingMessages,
              onSelectedMetadata: (metadata) =>
                  _onSelectMetadata(context, metadata),
              onRegenerate: () => context
                  .read<ChatBloc>()
                  .add(ChatEvent.regenerateAnswer(message.id, null, null)),
              onChangeFormat: (format) => context
                  .read<ChatBloc>()
                  .add(ChatEvent.regenerateAnswer(message.id, format, null)),
              onChangeModel: (model) => context
                  .read<ChatBloc>()
                  .add(ChatEvent.regenerateAnswer(message.id, null, model)),
              onStopStream: () => context.read<ChatBloc>().add(
                    const ChatEvent.stopStream(),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatMessage(
    BuildContext context,
    Message message,
    Animation<double> animation,
    Widget child,
  ) {
    return ChatMessage(
      message: message,
      animation: animation,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      receivedMessageScaleAnimationAlignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildScrollToBottom(
    BuildContext context,
    Animation<double> animation,
    VoidCallback onPressed,
  ) {
    return CustomScrollToBottom(
      animation: animation,
      onPressed: onPressed,
    );
  }

  Widget _buildChatAnimatedList(
    BuildContext context,
    ScrollController scrollController,
    ChatItem itemBuilder,
  ) {
    final bloc = context.read<ChatBloc>();

    if (bloc.chatController.messages.isEmpty) {
      return ChatWelcomePage(
        userProfile: userProfile,
        onSelectedQuestion: (question) {
          final aiPromptInputBloc = context.read<AIPromptInputBloc>();
          final showPredefinedFormats =
              aiPromptInputBloc.state.showPredefinedFormats;
          final predefinedFormat = aiPromptInputBloc.state.predefinedFormat;
          bloc.add(
            ChatEvent.sendMessage(
              message: question,
              format: showPredefinedFormats ? predefinedFormat : null,
            ),
          );
        },
      );
    }

    context
        .read<ChatSelectMessageBloc>()
        .add(ChatSelectMessageEvent.enableStartSelectingMessages());

    return BlocSelector<ChatSelectMessageBloc, ChatSelectMessageState, bool>(
      selector: (state) => state.isSelectingMessages,
      builder: (context, isSelectingMessages) {
        return ChatAnimatedListReversed(
          scrollController: scrollController,
          itemBuilder: itemBuilder,
          bottomPadding: isSelectingMessages
              ? 48.0 + DesktopAIChatSizes.messageActionBarIconSize
              : 8.0,
          onLoadPreviousMessages: () {
            bloc.add(const ChatEvent.loadPreviousMessages());
          },
        );
      },
    );
  }

  void _onSelectMetadata(
    BuildContext context,
    ChatMessageRefSource metadata,
  ) async {
    // When the source of metatdata is appflowy, which means it is a appflowy page
    if (metadata.source == "appflowy") {
      final sidebarView =
          await ViewBackendService.getView(metadata.id).toNullable();
      if (context.mounted) {
        openPageFromMessage(context, sidebarView);
      }
      return;
    }

    if (metadata.source == "web") {
      if (isURL(metadata.name)) {
        late Uri uri;
        try {
          uri = Uri.parse(metadata.name);
          // `Uri` identifies `localhost` as a scheme
          if (!uri.hasScheme || uri.scheme == 'localhost') {
            uri = Uri.parse("http://${metadata.name}");
            await InternetAddress.lookup(uri.host);
          }
          await launchUrl(uri);
        } catch (err) {
          Log.error("failed to open url $err");
        }
      }
      return;
    }
  }
}

class _Input extends StatefulWidget {
  const _Input({
    required this.view,
  });

  final ViewPB view;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final textController = AiPromptInputTextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatSelectMessageBloc, ChatSelectMessageState, bool>(
      selector: (state) => state.isSelectingMessages,
      builder: (context, isSelectingMessages) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            );
          },
          child: isSelectingMessages
              ? const SizedBox.shrink()
              : Padding(
                  padding: AIChatUILayout.safeAreaInsets(context),
                  child: BlocSelector<ChatBloc, ChatState, bool>(
                    selector: (state) {
                      return state.promptResponseState ==
                          PromptResponseState.ready;
                    },
                    builder: (context, canSendMessage) {
                      final chatBloc = context.read<ChatBloc>();

                      return UniversalPlatform.isDesktop
                          ? DesktopPromptInput(
                              isStreaming: !canSendMessage,
                              textController: textController,
                              onStopStreaming: () {
                                chatBloc.add(const ChatEvent.stopStream());
                              },
                              onSubmitted: (text, format, metadata) {
                                chatBloc.add(
                                  ChatEvent.sendMessage(
                                    message: text,
                                    format: format,
                                    metadata: metadata,
                                  ),
                                );
                              },
                              selectedSourcesNotifier:
                                  chatBloc.selectedSourcesNotifier,
                              onUpdateSelectedSources: (ids) {
                                chatBloc.add(
                                  ChatEvent.updateSelectedSources(
                                    selectedSourcesIds: ids,
                                  ),
                                );
                              },
                            )
                          : MobileChatInput(
                              isStreaming: !canSendMessage,
                              onStopStreaming: () {
                                chatBloc.add(const ChatEvent.stopStream());
                              },
                              onSubmitted: (text, format, metadata) {
                                chatBloc.add(
                                  ChatEvent.sendMessage(
                                    message: text,
                                    format: format,
                                    metadata: metadata,
                                  ),
                                );
                              },
                              selectedSourcesNotifier:
                                  chatBloc.selectedSourcesNotifier,
                              onUpdateSelectedSources: (ids) {
                                chatBloc.add(
                                  ChatEvent.updateSelectedSources(
                                    selectedSourcesIds: ids,
                                  ),
                                );
                              },
                            );
                    },
                  ),
                ),
        );
      },
    );
  }
}
