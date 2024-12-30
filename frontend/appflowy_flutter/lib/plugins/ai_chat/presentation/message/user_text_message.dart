import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_service.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_message_stream.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_user_message_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

import 'user_message_bubble.dart';

class ChatUserMessageWidget extends StatelessWidget {
  const ChatUserMessageWidget({
    super.key,
    required this.user,
    required this.message,
    required this.isCurrentUser,
  });

  final User user;
  final TextMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final stream = message.metadata?["$QuestionStream"];
    final messageText = stream is QuestionStream ? stream.text : message.text;

    return BlocProvider(
      create: (context) => ChatUserMessageBloc(
        text: messageText,
        questionStream: stream,
      ),
      child: ChatUserMessageBubble(
        message: message,
        isCurrentUser: isCurrentUser,
        files: _getFiles(),
        child: BlocBuilder<ChatUserMessageBloc, ChatUserMessageState>(
          builder: (context, state) {
            return Opacity(
              opacity: state.messageState.isFinish ? 1.0 : 0.8,
              child: TextMessageText(
                text: state.text,
              ),
            );
          },
        ),
      ),
    );
  }

  List<ChatFile> _getFiles() {
    if (message.metadata == null) {
      return const [];
    }

    final refSourceMetadata =
        message.metadata?[messageRefSourceJsonStringKey] as String?;
    if (refSourceMetadata != null) {
      return chatFilesFromMetadataString(refSourceMetadata);
    }

    final chatFileList =
        message.metadata![messageChatFileListKey] as List<ChatFile>?;
    return chatFileList ?? [];
  }
}

/// Widget to reuse the markdown capabilities, e.g., for previews.
class TextMessageText extends StatelessWidget {
  const TextMessageText({
    super.key,
    required this.text,
  });

  /// Text that is shown as markdown.
  final String text;

  @override
  Widget build(BuildContext context) {
    return FlowyText(
      text,
      lineHeight: 1.4,
      maxLines: null,
      selectable: true,
      color: AFThemeExtension.of(context).textColor,
    );
  }
}
