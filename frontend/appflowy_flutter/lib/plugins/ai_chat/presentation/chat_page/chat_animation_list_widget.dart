import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_chat_prelude.dart';
import 'package:appflowy/plugins/ai_chat/presentation/animated_chat_list.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_welcome_page.dart';
import 'package:appflowy/plugins/ai_chat/presentation/layout_define.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

class ChatAnimationListWidget extends StatefulWidget {
  const ChatAnimationListWidget({
    super.key,
    required this.userProfile,
    required this.scrollController,
    required this.itemBuilder,
  });

  final UserProfilePB userProfile;
  final ScrollController scrollController;
  final ChatItem itemBuilder;

  @override
  State<ChatAnimationListWidget> createState() =>
      _ChatAnimationListWidgetState();
}

class _ChatAnimationListWidgetState extends State<ChatAnimationListWidget> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();

    // this logic is quite weird, why don't we just get the message from the state?
    if (bloc.chatController.messages.isEmpty) {
      return ChatWelcomePage(
        userProfile: widget.userProfile,
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

    // don't call this in the build method
    context
        .read<ChatSelectMessageBloc>()
        .add(ChatSelectMessageEvent.enableStartSelectingMessages());

    // final bool reversed = false;

    return BlocSelector<ChatSelectMessageBloc, ChatSelectMessageState, bool>(
      selector: (state) => state.isSelectingMessages,
      builder: (context, isSelectingMessages) {
        // if (reversed) {
        //   return ChatAnimatedListReversed(
        //     scrollController: widget.scrollController,
        //     itemBuilder: widget.itemBuilder,
        //     bottomPadding: isSelectingMessages
        //         ? 48.0 + DesktopAIChatSizes.messageActionBarIconSize
        //         : 8.0,
        //     onLoadPreviousMessages: () {
        //       bloc.add(const ChatEvent.loadPreviousMessages());
        //     },
        //   );
        // } else {
        return ChatAnimatedList(
          scrollController: widget.scrollController,
          itemBuilder: widget.itemBuilder,
          bottomPadding: isSelectingMessages
              ? 48.0 + DesktopAIChatSizes.messageActionBarIconSize
              : 8.0,
          onLoadPreviousMessages: () {
            bloc.add(const ChatEvent.loadPreviousMessages());
          },
        );
        // }
      },
    );
  }
}
