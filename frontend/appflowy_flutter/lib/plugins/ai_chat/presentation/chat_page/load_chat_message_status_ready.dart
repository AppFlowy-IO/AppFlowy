import 'package:appflowy/plugins/ai_chat/presentation/chat_message_selector_banner.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_animation_list_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_footer.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/chat_message_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_page/text_message_widget.dart';
import 'package:appflowy/plugins/ai_chat/presentation/scroll_to_bottom.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatMessage;
import 'package:universal_platform/universal_platform.dart';

class LoadChatMessageStatusReady extends StatelessWidget {
  const LoadChatMessageStatusReady({
    super.key,
    required this.view,
    required this.userProfile,
    required this.chatController,
  });

  final ViewPB view;
  final UserProfilePB userProfile;
  final ChatController chatController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header, banner
        _buildHeader(context),
        // Chat body, a list of messages
        _buildBody(context),
        // Chat footer, a text input field with toolbar, send button, etc.
        _buildFooter(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ChatMessageSelectorBanner(
      view: view,
      allMessages: chatController.messages,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: _wrapConstraints(
          SelectionArea(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: Chat(
                chatController: chatController,
                user: User(id: userProfile.id.toString()),
                darkTheme: ChatTheme.fromThemeData(Theme.of(context)),
                theme: ChatTheme.fromThemeData(Theme.of(context)),
                builders: Builders(
                  // we have a custom input builder, so we don't need the default one
                  inputBuilder: (_) => const SizedBox.shrink(),
                  textMessageBuilder: (
                    context,
                    message,
                  ) =>
                      TextMessageWidget(
                    message: message,
                    userProfile: userProfile,
                    view: view,
                  ),
                  chatMessageBuilder: (
                    context,
                    message,
                    animation,
                    child,
                  ) =>
                      ChatMessage(
                    message: message,
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: child,
                  ),
                  scrollToBottomBuilder: (
                    context,
                    animation,
                    onPressed,
                  ) =>
                      CustomScrollToBottom(
                    animation: animation,
                    onPressed: onPressed,
                  ),
                  chatAnimatedListBuilder: (
                    context,
                    scrollController,
                    itemBuilder,
                  ) =>
                      ChatAnimationListWidget(
                    userProfile: userProfile,
                    scrollController: scrollController,
                    itemBuilder: itemBuilder,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _wrapConstraints(
      ChatFooter(view: view),
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
}
