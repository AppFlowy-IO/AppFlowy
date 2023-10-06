import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

DateFormat _dateFormat(BuildContext context) => DateFormat('MMM d, y');

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.reminderId,
    required this.title,
    required this.scheduled,
    required this.body,
    required this.isRead,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
  });

  final String reminderId;
  final String title;
  final Int64 scheduled;
  final String body;
  final bool isRead;

  final VoidCallback? onAction;
  final VoidCallback? onDelete;
  final void Function(bool isRead)? onReadChanged;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  final PopoverMutex mutex = PopoverMutex();
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: widget.onAction != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onAction,
            child: Opacity(
              opacity: widget.isRead ? 0.5 : 1,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  color: _isHovering && widget.onAction != null
                      ? AFThemeExtension.of(context).lightGreyHover
                      : Colors.transparent,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        const FlowySvg(FlowySvgs.time_s, size: Size.square(20)),
                        if (!widget.isRead)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AFThemeExtension.of(context).warning,
                              ),
                              child: const SizedBox(height: 8, width: 8),
                            ),
                          ),
                      ],
                    ),
                    const HSpace(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: FlowyText.semibold(widget.title),
                              ),
                              FlowyText.regular(
                                _scheduledString(widget.scheduled),
                                fontSize: 10,
                              ),
                            ],
                          ),
                          const VSpace(5),
                          FlowyText.regular(widget.body, maxLines: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isHovering)
            Positioned(
              right: 4,
              top: 4,
              child: NotificationItemActions(
                isRead: widget.isRead,
                onDelete: widget.onDelete,
                onReadChanged: widget.onReadChanged,
              ),
            ),
        ],
      ),
    );
  }

  String _scheduledString(Int64 secondsSinceEpoch) =>
      _dateFormat(context).format(
        DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch.toInt() * 1000),
      );

  void _onHover(bool isHovering) => setState(() => _isHovering = isHovering);
}

class NotificationItemActions extends StatelessWidget {
  const NotificationItemActions({
    super.key,
    required this.isRead,
    this.onDelete,
    this.onReadChanged,
  });

  final bool isRead;
  final VoidCallback? onDelete;
  final void Function(bool isRead)? onReadChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (isRead) ...[
              FlowyIconButton(
                height: 28,
                tooltipText:
                    LocaleKeys.reminderNotification_tooltipMarkUnread.tr(),
                icon: const FlowySvg(FlowySvgs.restore_s),
                onPressed: () => onReadChanged?.call(false),
              ),
            ] else ...[
              FlowyIconButton(
                height: 28,
                tooltipText:
                    LocaleKeys.reminderNotification_tooltipMarkRead.tr(),
                icon: const FlowySvg(FlowySvgs.messages_s),
                onPressed: () => onReadChanged?.call(true),
              ),
            ],
            VerticalDivider(
              width: 3,
              thickness: 1,
              indent: 2,
              endIndent: 2,
              color: Theme.of(context).dividerColor,
            ),
            FlowyIconButton(
              height: 28,
              tooltipText: LocaleKeys.reminderNotification_tooltipDelete.tr(),
              icon: const FlowySvg(FlowySvgs.delete_s),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
