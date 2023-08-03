import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    this.onAction,
    this.onDelete,
  });

  final VoidCallback? onAction;
  final VoidCallback? onDelete;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: widget.onAction != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onAction,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            color: _isHovering && widget.onAction != null
                ? AFThemeExtension.of(context).lightGreyHover
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FlowySvg(
                  name: 'editor/time',
                  size: Size.square(20),
                  alignment: Alignment.topCenter,
                ),
                const HSpace(10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FlowyText.semibold('Reminder'),
                          ),
                          FlowyText.regular(
                            '15:00 17/07/2023',
                            fontSize: 10,
                          ),
                        ],
                      ),
                      VSpace(5),
                      FlowyText.regular(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris placerat est ut eros facilisis pretium. Aliquam eget velit ut erat facilisis hendrerit vel.',
                        maxLines: 4,
                      ),
                      // TODO(Xazin): Body max length around 155 characters
                    ],
                  ),
                ),
                const HSpace(10),
                FlowyIconButton(
                  width: 20,
                  onPressed: () {
                    widget.onDelete?.call();
                    // TODO(Xazin): Delete notification event
                  },
                  icon: const FlowySvg(
                    name: 'home/trash',
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onHover(bool isHovering) => setState(() => _isHovering = isHovering);
}
