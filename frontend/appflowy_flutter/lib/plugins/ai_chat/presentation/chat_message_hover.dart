import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:styled_widget/styled_widget.dart';

class ChatMessageHover extends StatefulWidget {
  const ChatMessageHover({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;
  final Message message;

  @override
  State<ChatMessageHover> createState() => _ChatMessageHoverState();
}

class _ChatMessageHoverState extends State<ChatMessageHover> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      DecoratedBox(
        decoration: BoxDecoration(
          color: _isHover
              ? AFThemeExtension.of(context).lightGreyHover
              : Colors.transparent,
          borderRadius: Corners.s6Border,
        ),
        child: widget.child,
      ),
    ];

    if (_isHover) {
      if (widget.message is TextMessage) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CopyButton(
              textMessage: widget.message as TextMessage,
            ),
          ).positioned(top: 12, left: 12),
        );
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (p) => setState(() => _isHover = true),
      onExit: (p) => setState(() => _isHover = false),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: children,
      ),
    );
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
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).dividerColor),
          ),
          borderRadius: Corners.s6Border,
        ),
        child: FlowyIconButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          fillColor: Theme.of(context).cardColor,
          icon: FlowySvg(
            FlowySvgs.ai_copy_s,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: textMessage.text));
            showMessageToast(LocaleKeys.grid_row_copyProperty.tr());
          },
        ),
      ),
    );
  }
}
