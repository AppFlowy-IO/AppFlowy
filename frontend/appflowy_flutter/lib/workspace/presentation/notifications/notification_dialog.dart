import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_view.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_view_actions.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ReminderSortOption {
  descending,
  ascending,
}

extension _ReminderSort on Iterable<ReminderPB> {
  List<ReminderPB> sortByScheduledAt({
    ReminderSortOption reminderSortOption = ReminderSortOption.descending,
  }) =>
      sorted(
        (a, b) => switch (reminderSortOption) {
          ReminderSortOption.descending =>
            b.scheduledAt.compareTo(a.scheduledAt),
          ReminderSortOption.ascending =>
            a.scheduledAt.compareTo(b.scheduledAt),
        },
      );
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

  bool sortDescending = true;
  bool unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderBloc = getIt<ReminderBloc>();

    return BlocProvider<ReminderBloc>.value(
      value: reminderBloc,
      child: BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, state) {
          final sortOption = sortDescending
              ? ReminderSortOption.descending
              : ReminderSortOption.ascending;

          final pastReminders = state.pastReminders
              .where((r) => unreadOnly ? !r.isRead : true)
              .sortByScheduledAt(reminderSortOption: sortOption);

          final upcomingReminders = state.upcomingReminders.sortByScheduledAt(
            reminderSortOption: sortOption,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: 215,
                      child: TabBar(
                        controller: _controller,
                        indicator: UnderlineTabIndicator(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            width: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        tabs: [
                          Tab(
                            height: 26,
                            child: FlowyText.regular(
                              LocaleKeys.notificationHub_tabs_inbox.tr(),
                            ),
                          ),
                          Tab(
                            height: 26,
                            child: FlowyText.regular(
                              LocaleKeys.notificationHub_tabs_upcoming.tr(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  NotificationViewActions(
                    showUnreadOnlyAction: _controller.index == 0,
                    onSortChanged: (sort) =>
                        setState(() => sortDescending = sort),
                    onUnreadOnlyChanged: (unreadFilter) =>
                        setState(() => unreadOnly = unreadFilter),
                  ),
                ],
              ),
              const VSpace(4),
              Expanded(
                child: TabBarView(
                  controller: _controller,
                  children: [
                    NotificationsView(
                      shownReminders: pastReminders,
                      reminderBloc: reminderBloc,
                      views: widget.views,
                      mutex: widget.mutex,
                    ),
                    NotificationsView(
                      shownReminders: upcomingReminders,
                      reminderBloc: reminderBloc,
                      views: widget.views,
                      mutex: widget.mutex,
                      isUpcoming: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
