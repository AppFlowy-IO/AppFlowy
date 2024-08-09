import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatUserTextMessageWidget extends StatelessWidget {
  const ChatUserTextMessageWidget({
    super.key,
    required this.user,
    required this.messageUserId,
    required this.message,
    required this.metadata,
  });

  final User user;
  final String messageUserId;
  final TextMessage message;
  final String? metadata;

  @override
  Widget build(BuildContext context) {
    return TextMessageText(
      text: message.text,
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
      fontSize: 16,
      fontWeight: FontWeight.w500,
      maxLines: null,
      selectable: true,
      color: AFThemeExtension.of(context).textColor,
    );
  }
}
