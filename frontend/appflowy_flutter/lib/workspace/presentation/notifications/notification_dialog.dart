import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_hub_title.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_view.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension _ReminderSort on Iterable<ReminderPB> {
  List<ReminderPB> sortByScheduledAt() =>
      sorted((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
}

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({
    super.key,
    required this.views,
    required this.mutex,
  });

  final List<ViewPB> views;
  final PopoverMutex mutex;

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);
  final PopoverMutex _mutex = PopoverMutex();
  final ReminderBloc _reminderBloc = getIt<ReminderBloc>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _mutex.close();
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>.value(value: _reminderBloc),
        BlocProvider<NotificationFilterBloc>(
          create: (_) => NotificationFilterBloc(),
        ),
      ],
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, filterState) =>
            BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) {
            final List<ReminderPB> pastReminders = state.pastReminders
                .where((r) => filterState.showUnreadsOnly ? !r.isRead : true)
                .sortByScheduledAt();

            final List<ReminderPB> upcomingReminders =
                state.upcomingReminders.sortByScheduledAt();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NotificationHubTitle(),
                NotificationTabBar(tabController: _controller),
                // TODO(Xazin): Resolve issue with taking up
                //  max amount of vertical space
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      NotificationsView(
                        shownReminders: pastReminders,
                        reminderBloc: _reminderBloc,
                        views: widget.views,
                        onDelete: _onDelete,
                        onAction: _onAction,
                        onReadChanged: _onReadChanged,
                        actionBar: _InboxActionBar(
                          hasUnreads: state.hasUnreads,
                          showUnreadsOnly: filterState.showUnreadsOnly,
                        ),
                      ),
                      NotificationsView(
                        shownReminders: upcomingReminders,
                        reminderBloc: _reminderBloc,
                        views: widget.views,
                        isUpcoming: true,
                        onAction: _onAction,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onAction(ReminderPB reminder) {
    final view = widget.views.firstWhereOrNull(
      (view) => view.id == reminder.objectId,
    );

    if (view == null) {
      return;
    }

    _reminderBloc.add(
      ReminderEvent.pressReminder(reminderId: reminder.id),
    );

    widget.mutex.close();
  }

  void _onDelete(ReminderPB reminder) {
    _reminderBloc.add(ReminderEvent.remove(reminder: reminder));
  }

  void _onReadChanged(ReminderPB reminder, bool isRead) {
    _reminderBloc.add(
      ReminderEvent.update(ReminderUpdate(id: reminder.id, isRead: isRead)),
    );
  }
}

class _InboxActionBar extends StatelessWidget {
  const _InboxActionBar({
    required this.hasUnreads,
    required this.showUnreadsOnly,
  });

  final bool hasUnreads;
  final bool showUnreadsOnly;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MarkAsReadButton(
              onMarkAllRead: !hasUnreads
                  ? null
                  : () => context
                      .read<ReminderBloc>()
                      .add(const ReminderEvent.markAllRead()),
            ),
            _ToggleUnreadsButton(
              showUnreadsOnly: showUnreadsOnly,
              onToggled: (showUnreadsOnly) => context
                  .read<NotificationFilterBloc>()
                  .add(const NotificationFilterEvent.toggleShowUnreadsOnly()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleUnreadsButton extends StatefulWidget {
  const _ToggleUnreadsButton({
    required this.onToggled,
    this.showUnreadsOnly = false,
  });

  final Function(bool) onToggled;
  final bool showUnreadsOnly;

  @override
  State<_ToggleUnreadsButton> createState() => _ToggleUnreadsButtonState();
}

class _ToggleUnreadsButtonState extends State<_ToggleUnreadsButton> {
  late bool showUnreadsOnly = widget.showUnreadsOnly;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() => showUnreadsOnly = newSelection.first);
        widget.onToggled(showUnreadsOnly);
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        side: MaterialStatePropertyAll(
          BorderSide(color: Theme.of(context).dividerColor),
        ),
        shape: const MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Corners.s6Border),
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (state) {
            if (state.contains(MaterialState.hovered) ||
                state.contains(MaterialState.selected) ||
                state.contains(MaterialState.pressed)) {
              return Theme.of(context).colorScheme.onSurface;
            }

            return AFThemeExtension.of(context).textColor;
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (state) {
            if (state.contains(MaterialState.hovered) ||
                state.contains(MaterialState.selected) ||
                state.contains(MaterialState.pressed)) {
              return Theme.of(context).colorScheme.primary;
            }

            return Theme.of(context).cardColor;
          },
        ),
      ),
      segments: [
        ButtonSegment<bool>(
          value: false,
          label: Text(
            LocaleKeys.notificationHub_actions_showAll.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text(
            LocaleKeys.notificationHub_actions_showUnreads.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
      selected: <bool>{showUnreadsOnly},
    );
  }
}

class _MarkAsReadButton extends StatefulWidget {
  final VoidCallback? onMarkAllRead;

  const _MarkAsReadButton({this.onMarkAllRead});

  @override
  State<_MarkAsReadButton> createState() => _MarkAsReadButtonState();
}

class _MarkAsReadButtonState extends State<_MarkAsReadButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.onMarkAllRead != null ? 1 : 0.5,
      child: FlowyHover(
        onHover: (isHovering) => setState(() => _isHovering = isHovering),
        resetHoverOnRebuild: false,
        child: FlowyTextButton(
          LocaleKeys.notificationHub_actions_markAllRead.tr(),
          fontColor: widget.onMarkAllRead != null && _isHovering
              ? Theme.of(context).colorScheme.onSurface
              : AFThemeExtension.of(context).textColor,
          heading: FlowySvg(
            FlowySvgs.checklist_s,
            color: widget.onMarkAllRead != null && _isHovering
                ? Theme.of(context).colorScheme.onSurface
                : AFThemeExtension.of(context).textColor,
          ),
          hoverColor: widget.onMarkAllRead != null && _isHovering
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: widget.onMarkAllRead,
        ),
      ),
    );
  }
}
