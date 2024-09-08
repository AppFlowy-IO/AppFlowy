import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_input_file_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

class ChatInputFile extends StatelessWidget {
  const ChatInputFile({
    required this.chatId,
    required this.files,
    required this.onDeleted,
    super.key,
  });
  final List<ChatFile> files;
  final String chatId;

  final Function(ChatFile) onDeleted;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = files
        .map(
          (file) => ChatFilePreview(
            chatId: chatId,
            file: file,
            onDeleted: onDeleted,
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

class ChatFilePreview extends StatelessWidget {
  const ChatFilePreview({
    required this.chatId,
    required this.file,
    required this.onDeleted,
    super.key,
  });
  final String chatId;
  final ChatFile file;
  final Function(ChatFile) onDeleted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatInputFileBloc(chatId: chatId, file: file)
        ..add(const ChatInputFileEvent.initial()),
      child: BlocBuilder<ChatInputFileBloc, ChatInputFileState>(
        builder: (context, state) {
          return FlowyHover(
            builder: (context, onHover) {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 260,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 14,
                        ),
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
                      if (onHover)
                        _CloseButton(
                          onPressed: () => onDeleted(file),
                        ).positioned(top: -6, right: -6),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 24,
      height: 24,
      isSelected: true,
      radius: BorderRadius.circular(12),
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      icon: const FlowySvg(
        FlowySvgs.close_s,
        size: Size.square(20),
      ),
      onPressed: onPressed,
    );
  }
}
