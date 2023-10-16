import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.reminderId,
    required this.title,
    required this.scheduled,
    required this.body,
    required this.isRead,
    this.includeTime = false,
    this.readOnly = false,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
  });

  final String reminderId;
  final String title;
  final Int64 scheduled;
  final String body;
  final bool includeTime;
  final bool readOnly;
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
              opacity: widget.isRead && !widget.readOnly ? 0.5 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isHovering && widget.onAction != null
                      ? AFThemeExtension.of(context).lightGreyHover
                      : Colors.transparent,
                  border: widget.isRead || widget.readOnly
                      ? null
                      : Border(
                          left: BorderSide(
                            width: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlowySvg(
                        FlowySvgs.time_s,
                        size: const Size.square(20),
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const HSpace(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FlowyText.semibold(
                              widget.title,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            // TODO(Xazin): Relative time + View Name
                            FlowyText.regular(
                              _scheduledString(
                                widget.scheduled,
                                widget.includeTime,
                              ),
                              fontSize: 10,
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
          ),
          if (_isHovering && !widget.readOnly)
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

  String _scheduledString(Int64 secondsSinceEpoch, bool includeTime) {
    final appearance = context.read<AppearanceSettingsCubit>().state;
    return appearance.dateFormat.formatDate(
      DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch.toInt() * 1000),
      includeTime,
      appearance.timeFormat,
    );
  }

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
