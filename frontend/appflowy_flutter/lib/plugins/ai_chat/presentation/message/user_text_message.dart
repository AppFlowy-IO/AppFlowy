import 'package:appflowy/plugins/ai_chat/application/chat_file_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_user_message_bloc.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return BlocProvider(
      create: (context) => ChatUserMessageBloc(
        message: message,
        metadata: metadata,
      ),
      child: BlocBuilder<ChatUserMessageBloc, ChatUserMessageState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (state.files.isNotEmpty) ...[
                _MessageFileList(files: state.files),
                const VSpace(6),
              ],
              TextMessageText(
                text: message.text,
              ),
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
      fontSize: 16,
      fontWeight: FontWeight.w500,
      maxLines: null,
      selectable: true,
      color: AFThemeExtension.of(context).textColor,
    );
  }
}

class _MessageFileList extends StatelessWidget {
  const _MessageFileList({required this.files});

  final List<ChatFile> files;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = files
        .map(
          (file) => _MessageFile(
            file: file,
          ),
        )
        .toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: children,
    );
  }
}

class _MessageFile extends StatelessWidget {
  const _MessageFile({required this.file});

  final ChatFile file;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            file.fileType.icon,
            const HSpace(6),
            Flexible(
              child: FlowyText(
                file.fileName,
                fontSize: 12,
                maxLines: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
