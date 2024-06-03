import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';

class ChatPopupMenu extends StatefulWidget {
  const ChatPopupMenu({
    super.key,
    required this.onAction,
    required this.builder,
  });

  final Function(ChatMessageAction) onAction;
  final Widget Function(BuildContext context) builder;

  @override
  State<ChatPopupMenu> createState() => _ChatPopupMenuState();
}

class _ChatPopupMenuState extends State<ChatPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ChatMessageActionWrapper>(
      asBarrier: true,
      actions: ChatMessageAction.values
          .map((action) => ChatMessageActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return GestureDetector(
          onLongPress: () {
            controller.show();
          },
          child: widget.builder(context),
        );
      },
      onSelected: (action, controller) async {
        widget.onAction(action.inner);
        controller.close();
      },
      direction: PopoverDirection.bottomWithCenterAligned,
    );
  }
}

enum ChatMessageAction {
  copy,
}

class ChatMessageActionWrapper extends ActionCell {
  ChatMessageActionWrapper(this.inner);

  final ChatMessageAction inner;

  @override
  Widget? leftIcon(Color iconColor) => null;

  @override
  String get name => inner.name;
}

extension ChatMessageActionExtension on ChatMessageAction {
  String get name {
    switch (this) {
      case ChatMessageAction.copy:
        return LocaleKeys.document_plugins_contextMenu_copy.tr();
    }
  }
}
