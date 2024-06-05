import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_user_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:styled_widget/styled_widget.dart';

class ChatUserMessageBubble extends StatelessWidget {
  const ChatUserMessageBubble({
    super.key,
    required this.message,
    required this.child,
  });

  final Message message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(6));
    final backgroundColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return BlocProvider(
      create: (context) => ChatUserMessageBloc(message: message),
      child: BlocBuilder<ChatUserMessageBloc, ChatUserMessageState>(
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _wrapHover(
              Flexible(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: backgroundColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: child,
                  ),
                ),
              ),
              // ),
              BlocBuilder<ChatUserMessageBloc, ChatUserMessageState>(
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ChatUserAvatar(
                      iconUrl: state.member?.avatarUrl ?? "",
                      name: state.member?.name ?? "",
                      size: 36,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatUserMessageHover extends StatefulWidget {
  const ChatUserMessageHover({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;
  final bool autoShowHover = true;

  @override
  State<ChatUserMessageHover> createState() => _ChatUserMessageHoverState();
}

class _ChatUserMessageHoverState extends State<ChatUserMessageHover> {
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
      if (widget.message is TextMessage) {
        children.add(
          EditButton(
            textMessage: widget.message as TextMessage,
          ).positioned(right: 0, bottom: 0),
        );
      }
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
}

class EditButton extends StatelessWidget {
  const EditButton({
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
        onPressed: () {},
      ),
    );
  }
}
