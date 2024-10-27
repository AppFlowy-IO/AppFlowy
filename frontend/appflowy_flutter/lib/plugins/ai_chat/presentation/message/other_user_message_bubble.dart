import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_member_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_avatar.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_popmenu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:universal_platform/universal_platform.dart';

const _leftPadding = 16.0;

class OtherUserMessageBubble extends StatelessWidget {
  const OtherUserMessageBubble({
    super.key,
    required this.message,
    required this.child,
  });

  final Message message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: _leftPadding);
    final childWithPadding = Padding(padding: padding, child: child);
    final widget = UniversalPlatform.isMobile
        ? _wrapPopMenu(childWithPadding)
        : _wrapHover(childWithPadding);

    if (context.read<ChatMemberBloc>().state.members[message.author.id] ==
        null) {
      context
          .read<ChatMemberBloc>()
          .add(ChatMemberEvent.getMemberInfo(message.author.id));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocConsumer<ChatMemberBloc, ChatMemberState>(
          listenWhen: (previous, current) {
            return previous.members[message.author.id] !=
                current.members[message.author.id];
          },
          listener: (context, state) {},
          builder: (context, state) {
            final member = state.members[message.author.id];
            return ChatUserAvatar(
              iconUrl: member?.info.avatarUrl ?? "",
              name: member?.info.name ?? "",
              defaultName: "",
            );
          },
        ),
        Expanded(child: widget),
      ],
    );
  }

  OtherUserMessageHover _wrapHover(Padding child) {
    return OtherUserMessageHover(
      message: message,
      child: child,
    );
  }

  ChatPopupMenu _wrapPopMenu(Padding childWithPadding) {
    return ChatPopupMenu(
      onAction: (action) {
        if (action == ChatMessageAction.copy && message is TextMessage) {
          Clipboard.setData(ClipboardData(text: (message as TextMessage).text));
          showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
        }
      },
      builder: (context) => childWithPadding,
    );
  }
}

class OtherUserMessageHover extends StatefulWidget {
  const OtherUserMessageHover({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;
  final bool autoShowHover = true;

  @override
  State<OtherUserMessageHover> createState() => _OtherUserMessageHoverState();
}

class _OtherUserMessageHoverState extends State<OtherUserMessageHover> {
  bool _isHover = false;

  @override
  void initState() {
    super.initState();
    _isHover = widget.autoShowHover ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: Corners.s6Border,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: widget.child,
        ),
      ),
    ];

    if (_isHover) {
      children.addAll(_buildOnHoverItems());
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (p) => setState(() {
        if (widget.autoShowHover) {
          _isHover = true;
        }
      }),
      onExit: (p) => setState(() {
        if (widget.autoShowHover) {
          _isHover = false;
        }
      }),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: children,
      ),
    );
  }

  List<Widget> _buildOnHoverItems() {
    final List<Widget> children = [];
    if (widget.message is TextMessage) {
      children.add(
        CopyButton(
          textMessage: widget.message as TextMessage,
        ).positioned(left: _leftPadding, bottom: 0),
      );
    }

    return children;
  }
}

class CopyButton extends StatelessWidget {
  const CopyButton({
    super.key,
    required this.textMessage,
  });
  final TextMessage textMessage;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.settings_menu_clickToCopy.tr(),
      child: FlowyIconButton(
        width: 24,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        fillColor: Theme.of(context).cardColor,
        icon: FlowySvg(
          FlowySvgs.ai_copy_s,
          size: const Size.square(14),
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () async {
          final document = customMarkdownToDocument(textMessage.text);
          await getIt<ClipboardService>().setData(
            ClipboardServiceData(
              plainText: textMessage.text,
              inAppJson: jsonEncode(document.toJson()),
            ),
          );
          if (context.mounted) {
            showToastNotification(
              context,
              message: LocaleKeys.grid_url_copiedNotification.tr(),
            );
          }
        },
      ),
    );
  }
}
