import 'dart:async';

import 'package:appflowy/ai/service/ai_prompt_input_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/ai_chat_prelude.dart';
import 'package:appflowy/plugins/ai_chat/presentation/animated_chat_list.dart';
import 'package:appflowy/plugins/ai_chat/presentation/animated_chat_list_reversed.dart';
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
    this.enableReversedList = false,
  });

  final UserProfilePB userProfile;
  final ScrollController scrollController;
  final ChatItem itemBuilder;
  final bool enableReversedList;

  @override
  State<ChatAnimationListWidget> createState() =>
      _ChatAnimationListWidgetState();
}

class _ChatAnimationListWidgetState extends State<ChatAnimationListWidget> {
  bool hasMessage = false;
  StreamSubscription<ChatOperation>? subscription;

  @override
  void initState() {
    super.initState();

    final bloc = context.read<ChatBloc>();
    if (bloc.chatController.messages.isNotEmpty) {
      hasMessage = true;
    }

    subscription = bloc.chatController.operationsStream.listen((operation) {
      final newHasMessage = bloc.chatController.messages.isNotEmpty;

      if (!mounted) {
        return;
      }

      if (hasMessage != newHasMessage) {
        setState(() {
          hasMessage = newHasMessage;
        });
      }
    });
  }

  @override
  void dispose() {
    subscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatBloc>();

    if (!hasMessage) {
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
        return widget.enableReversedList
            ? ChatAnimatedListReversed(
                scrollController: widget.scrollController,
                itemBuilder: widget.itemBuilder,
                bottomPadding: isSelectingMessages
                    ? 48.0 + DesktopAIChatSizes.messageActionBarIconSize
                    : 8.0,
                onLoadPreviousMessages: () {
                  if (bloc.isClosed) {
                    return;
                  }
                  bloc.add(const ChatEvent.loadPreviousMessages());
                },
              )
            : ChatAnimatedList(
                scrollController: widget.scrollController,
                itemBuilder: widget.itemBuilder,
                bottomPadding: isSelectingMessages
                    ? 48.0 + DesktopAIChatSizes.messageActionBarIconSize
                    : 8.0,
                onLoadPreviousMessages: () {
                  if (bloc.isClosed) {
                    return;
                  }
                  bloc.add(const ChatEvent.loadPreviousMessages());
                },
              );
      },
    );
  }
}
