import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_entity.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_user_message_bubble_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_avatar.dart';
import 'package:appflowy/plugins/ai_chat/presentation/layout_define.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatUserMessageBubble extends StatelessWidget {
  const ChatUserMessageBubble({
    super.key,
    required this.message,
    required this.child,
    this.isCurrentUser = true,
  });

  final Message message;
  final Widget child;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    if (context.read<ChatMemberBloc>().state.members[message.author.id] ==
        null) {
      context
          .read<ChatMemberBloc>()
          .add(ChatMemberEvent.getMemberInfo(message.author.id));
    }

    return BlocProvider(
      create: (context) => ChatUserMessageBubbleBloc(
        message: message,
      ),
      child: BlocBuilder<ChatUserMessageBubbleBloc, ChatUserMessageBubbleState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (state.files.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: _MessageFileList(files: state.files),
                ),
                const VSpace(6),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getChildren(context),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> getChildren(BuildContext context) {
    if (isCurrentUser) {
      return [
        _buildBubble(context),
        const HSpace(DesktopAIConvoSizes.avatarAndChatBubbleSpacing),
        _buildAvatar(),
      ];
    } else {
      return [
        _buildAvatar(),
        const HSpace(DesktopAIConvoSizes.avatarAndChatBubbleSpacing),
        _buildBubble(context),
      ];
    }
  }

  Widget _buildAvatar() {
    return BlocBuilder<ChatMemberBloc, ChatMemberState>(
      builder: (context, state) {
        final member = state.members[message.author.id];
        return ChatUserAvatar(
          iconUrl: member?.info.avatarUrl ?? "",
          name: member?.info.name ?? "",
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: child,
      ),
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
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.end,
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowySvg(
              FlowySvgs.page_m,
              size: const Size.square(16),
              color: Theme.of(context).hintColor,
            ),
            const HSpace(6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FlowyText(
                  file.fileName,
                  fontSize: 12,
                  maxLines: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
