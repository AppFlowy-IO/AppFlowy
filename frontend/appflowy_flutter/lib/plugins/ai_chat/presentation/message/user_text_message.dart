import 'package:appflowy/plugins/ai_chat/application/chat_user_message_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatUserMessageWidget extends StatelessWidget {
  const ChatUserMessageWidget({
    super.key,
    required this.user,
    required this.message,
  });

  final User user;
  final dynamic message;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatUserMessageBloc(message: message)
        ..add(const ChatUserMessageEvent.initial()),
      child: BlocBuilder<ChatUserMessageBloc, ChatUserMessageState>(
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextMessageText(
                  text: state.text,
                ),
              ),
              if (!state.messageState.isFinish) ...[
                const HSpace(6),
                const CircularProgressIndicator.adaptive(),
              ],
            ],
          );
        },
      ),
    );
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
