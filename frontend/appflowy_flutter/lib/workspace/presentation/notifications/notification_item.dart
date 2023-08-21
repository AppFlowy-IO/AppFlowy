import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateFormat _dateFormat(BuildContext context) => DateFormat('MMM d, y');

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.title,
    required this.scheduled,
    required this.body,
    this.onAction,
    this.onDelete,
  });

  final String title;
  final Int64 scheduled;
  final String body;

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
                const FlowySvg(FlowySvgs.time_s, size: Size.square(20)),
                const HSpace(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: FlowyText.semibold(widget.title)),
                          FlowyText.regular(
                            _scheduledString(widget.scheduled),
                            fontSize: 10,
                          ),
                        ],
                      ),
                      const VSpace(5),
                      FlowyText.regular(
                        widget.body,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const HSpace(10),
                FlowyIconButton(
                  width: 20,
                  onPressed: () => widget.onDelete?.call(),
                  icon: const FlowySvg(FlowySvgs.delete_s),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _scheduledString(Int64 secondsSinceEpoch) =>
      _dateFormat(context).format(
        DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch.toInt() * 1000),
      );

  void _onHover(bool isHovering) => setState(() => _isHovering = isHovering);
}
