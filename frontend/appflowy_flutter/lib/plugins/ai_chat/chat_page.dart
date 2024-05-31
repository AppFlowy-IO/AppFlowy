import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' show Chat;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'presentation/chat_input.dart';
import 'presentation/chat_message_hover.dart';
import 'presentation/chat_popmenu.dart';
import 'presentation/chat_theme.dart';

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
      return buildUnsupportWidget();
    }
  }

  Widget buildChatWidget() {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                onMessageTap: (BuildContext _, types.Message message) {
                  blocContext
                      .read<ChatBloc>()
                      .add(ChatEvent.tapMessage(message));
                },
                onSendPressed: (types.PartialText message) {
                  // We use custom bottom widget for chat input, so
                  // do not need to handle this event.
                },
                customBottomWidget: buildChatInput(blocContext),
                user: _user,
                theme: buildTheme(context),
                customMessageBuilder: (message, {required messageWidth}) {
                  return const SizedBox(
                    width: 100,
                    height: 50,
                    child: CircularProgressIndicator.adaptive(),
                  );
                },
                onEndReached: () async {
                  if (state.hasMore &&
                      state.loadingPreviousStatus !=
                          const LoadingState.loading()) {
                    blocContext
                        .read<ChatBloc>()
                        .add(const ChatEvent.loadPrevMessage());
                  }
                },
                emptyState: const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                messageWidthRatio: 0.7,
                bubbleBuilder: (
                  child, {
                  required message,
                  required nextMessageInGroup,
                }) =>
                    buildBubble(message, child),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildUnsupportWidget() {
    return Center(
      child: FlowyText(
        LocaleKeys.chat_unsupportedCloudPrompt.tr(),
        fontSize: 20,
      ),
    );
  }

  Widget buildBubble(Message message, Widget child) {
    final isAuthor = message.author.id == _user.id;
    const borderRadius = BorderRadius.all(Radius.circular(20));
    final decoratedChild = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: !isAuthor || message.type == types.MessageType.image
            ? AFThemeExtension.of(context).tint1
            : Theme.of(context).colorScheme.secondary,
      ),
      child: child,
    );

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
      return ClipRRect(
        borderRadius: borderRadius,
        child: ChatMessageHover(
          message: message,
          child: decoratedChild,
        ),
      );
    }
  }

  Widget buildChatInput(BuildContext context) {
    final query = MediaQuery.of(context);
    final safeAreaInsets = isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : EdgeInsets.zero;
    return Padding(
      padding: safeAreaInsets,
      child: ChatInput(
        onSendPressed: (message) => onSendPressed(context, message),
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

  void onSendPressed(BuildContext context, types.PartialText message) {
    context.read<ChatBloc>().add(ChatEvent.sendMessage(message.text));
  }
}
