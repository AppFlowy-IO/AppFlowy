import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.reminder,
    required this.title,
    required this.scheduled,
    required this.body,
    required this.isRead,
    this.block,
    this.includeTime = false,
    this.readOnly = false,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
    this.view,
  });

  final ReminderPB reminder;
  final String title;
  final Int64 scheduled;
  final String body;
  final bool isRead;
  final ViewPB? view;

  /// If [block] is provided, then [body] will be shown only if
  /// [block] fails to fetch.
  ///
  /// [block] is rendered as a result of a [FutureBuilder].
  ///
  final Future<Node?>? block;

  final bool includeTime;
  final bool readOnly;

  final void Function(int? path)? onAction;
  final VoidCallback? onDelete;
  final void Function(bool isRead)? onReadChanged;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  final PopoverMutex mutex = PopoverMutex();
  bool _isHovering = false;
  int? path;

  late final String infoString;

  @override
  void initState() {
    super.initState();
    widget.block?.then((b) => path = b?.path.first);
    infoString = _buildInfoString();
  }

  @override
  void dispose() {
    mutex.dispose();
    super.dispose();
  }

  String _buildInfoString() {
    String scheduledString =
        _scheduledString(widget.scheduled, widget.includeTime);

    if (widget.view != null) {
      scheduledString = '$scheduledString - ${widget.view!.name}';
    }

    return scheduledString;
  }

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
            onTap: () => widget.onAction?.call(path),
            child: AbsorbPointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: UniversalPlatform.isMobile
                        ? BorderSide(
                            color: AFThemeExtension.of(context).calloutBGColor,
                          )
                        : BorderSide.none,
                  ),
                ),
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
                                width: UniversalPlatform.isMobile ? 4 : 2,
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
                            size: Size.square(
                              UniversalPlatform.isMobile ? 24 : 20,
                            ),
                            color: AFThemeExtension.of(context).textColor,
                          ),
                          const HSpace(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FlowyText.semibold(
                                  widget.title,
                                  fontSize:
                                      UniversalPlatform.isMobile ? 16 : 14,
                                  color: AFThemeExtension.of(context).textColor,
                                ),
                                // TODO(Xazin): Relative time
                                FlowyText.regular(
                                  infoString,
                                  fontSize:
                                      UniversalPlatform.isMobile ? 12 : 10,
                                ),
                                const VSpace(5),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: Corners.s8Border,
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: _NotificationContent(
                                    block: widget.block,
                                    reminder: widget.reminder,
                                    body: widget.body,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (UniversalPlatform.isMobile && !widget.readOnly ||
              _isHovering && !widget.readOnly)
            Positioned(
              right: UniversalPlatform.isMobile ? 8 : 4,
              top: UniversalPlatform.isMobile ? 8 : 4,
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

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.body,
    required this.reminder,
    required this.block,
  });

  final String body;
  final ReminderPB reminder;
  final Future<Node?>? block;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Node?>(
      future: block,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return FlowyText.regular(body, maxLines: 4);
        }

        return IntrinsicHeight(
          child: NotificationDocumentContent(
            nodes: [snapshot.data!],
            reminder: reminder,
          ),
        );
      },
    );
  }
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
    final double size = UniversalPlatform.isMobile ? 40.0 : 30.0;

    return Container(
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: AFThemeExtension.of(context).lightGreyHover,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (isRead) ...[
              FlowyIconButton(
                height: size,
                width: size,
                tooltipText:
                    LocaleKeys.reminderNotification_tooltipMarkUnread.tr(),
                icon: const FlowySvg(FlowySvgs.restore_s),
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                onPressed: () => onReadChanged?.call(false),
              ),
            ] else ...[
              FlowyIconButton(
                height: size,
                width: size,
                tooltipText:
                    LocaleKeys.reminderNotification_tooltipMarkRead.tr(),
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                icon: const FlowySvg(FlowySvgs.messages_s),
                onPressed: () => onReadChanged?.call(true),
              ),
            ],
            VerticalDivider(
              width: 3,
              thickness: 1,
              indent: 2,
              endIndent: 2,
              color: UniversalPlatform.isMobile
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).dividerColor,
            ),
            FlowyIconButton(
              height: size,
              width: size,
              tooltipText: LocaleKeys.reminderNotification_tooltipDelete.tr(),
              icon: const FlowySvg(FlowySvgs.delete_s),
              iconColorOnHover: Theme.of(context).colorScheme.onSurface,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
