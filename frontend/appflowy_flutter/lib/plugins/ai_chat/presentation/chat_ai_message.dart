import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_ai_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_avatar.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_input.dart';
import 'package:appflowy/plugins/ai_chat/presentation/chat_popmenu.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
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

const _leftPadding = 16.0;

class ChatAIMessageBubble extends StatelessWidget {
  const ChatAIMessageBubble({
    super.key,
    required this.message,
    required this.child,
    this.customMessageType,
  });

  final Message message;
  final Widget child;
  final OnetimeMessageType? customMessageType;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: _leftPadding);
    final childWithPadding = Padding(padding: padding, child: child);

    return BlocProvider(
      create: (context) => ChatAIMessageBloc(message: message),
      child: BlocBuilder<ChatAIMessageBloc, ChatAIMessageState>(
        builder: (context, state) {
          final widget = isMobile
              ? _wrapPopMenu(childWithPadding)
              : _wrapHover(childWithPadding);

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatBorderedCircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const FlowySvg(
                  FlowySvgs.flowy_ai_chat_logo_s,
                  size: Size.square(24),
                ),
              ),
              Expanded(child: widget),
            ],
          );
        },
      ),
    );
  }

  ChatAIMessageHover _wrapHover(Padding child) {
    return ChatAIMessageHover(
      message: message,
      customMessageType: customMessageType,
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

class ChatAIMessageHover extends StatefulWidget {
  const ChatAIMessageHover({
    super.key,
    required this.child,
    required this.message,
    this.customMessageType,
  });

  final Widget child;
  final Message message;
  final bool autoShowHover = true;
  final OnetimeMessageType? customMessageType;

  @override
  State<ChatAIMessageHover> createState() => _ChatAIMessageHoverState();
}

class _ChatAIMessageHoverState extends State<ChatAIMessageHover> {
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
          padding: const EdgeInsets.only(bottom: 40),
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
    if (widget.customMessageType != null) {
      //
    } else {
      if (widget.message is TextMessage) {
        children.add(
          CopyButton(
            textMessage: widget.message as TextMessage,
          ).positioned(left: _leftPadding, bottom: 0),
        );
      }
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
        onPressed: () {
          Clipboard.setData(ClipboardData(text: textMessage.text));
          showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
        },
      ),
    );
  }
}
