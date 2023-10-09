import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_grouped_view.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_view.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension _ReminderSort on Iterable<ReminderPB> {
  List<ReminderPB> sortByScheduledAt({
    bool isDescending = true,
  }) =>
      sorted(
        (a, b) => isDescending
            ? b.scheduledAt.compareTo(a.scheduledAt)
            : a.scheduledAt.compareTo(b.scheduledAt),
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
  final PopoverMutex _mutex = PopoverMutex();

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
    final reminderBloc = getIt<ReminderBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>.value(value: reminderBloc),
        BlocProvider<NotificationFilterBloc>(
          create: (_) => NotificationFilterBloc(),
        ),
      ],
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, filterState) =>
            BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) {
            final sortDescending =
                filterState.sortBy == NotificationSortOption.descending;

            final List<ReminderPB> pastReminders = state.pastReminders
                .where((r) => filterState.showUnreadsOnly ? !r.isRead : true)
                .sortByScheduledAt(isDescending: sortDescending);

            final List<ReminderPB> upcomingReminders = state.upcomingReminders
                .sortByScheduledAt(isDescending: sortDescending);

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
                    NotificationViewFilters(),
                  ],
                ),
                const VSpace(4),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      if (!filterState.groupByDate) ...[
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
                      ] else ...[
                        NotificationsGroupView(
                          groupedReminders: groupBy<ReminderPB, DateTime>(
                            pastReminders,
                            (r) => DateTime.fromMillisecondsSinceEpoch(
                              r.scheduledAt.toInt() * 1000,
                            ).withoutTime,
                          ),
                          reminderBloc: reminderBloc,
                          views: widget.views,
                          mutex: widget.mutex,
                        ),
                        NotificationsGroupView(
                          groupedReminders: groupBy<ReminderPB, DateTime>(
                            upcomingReminders,
                            (r) => DateTime.fromMillisecondsSinceEpoch(
                              r.scheduledAt.toInt() * 1000,
                            ).withoutTime,
                          ),
                          reminderBloc: reminderBloc,
                          views: widget.views,
                          mutex: widget.mutex,
                          isUpcoming: true,
                        ),
                      ],
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
}

class NotificationViewFilters extends StatelessWidget {
  NotificationViewFilters({super.key});
  final PopoverMutex _mutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationFilterBloc>.value(
      value: context.read<NotificationFilterBloc>(),
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, state) {
          return AppFlowyPopover(
            mutex: _mutex,
            offset: const Offset(0, 5),
            constraints: BoxConstraints.loose(const Size(225, 200)),
            direction: PopoverDirection.bottomWithLeftAligned,
            popupBuilder: (popoverContext) {
              // TODO(Xazin): This is a workaround until we have resolved
              //  the issues with closing popovers on leave/outside-clicks
              return MouseRegion(
                onExit: (_) => _mutex.close(),
                child: NotificationFilterPopover(
                  bloc: context.read<NotificationFilterBloc>(),
                ),
              );
            },
            child: FlowyIconButton(
              isSelected: state.hasFilters,
              iconColorOnHover: Theme.of(context).colorScheme.onSurface,
              icon: const FlowySvg(FlowySvgs.filter_s),
            ),
          );
        },
      ),
    );
  }
}

class NotificationFilterPopover extends StatelessWidget {
  const NotificationFilterPopover({
    super.key,
    required this.bloc,
  });

  final NotificationFilterBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SortByOption(bloc: bloc),
        _ShowUnreadsToggle(bloc: bloc),
        _GroupByDateToggle(bloc: bloc),
        BlocProvider<NotificationFilterBloc>.value(
          value: bloc,
          child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
            builder: (context, state) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 115,
                    child: FlowyButton(
                      disable: !state.hasFilters,
                      onTap: state.hasFilters
                          ? () =>
                              bloc.add(const NotificationFilterEvent.reset())
                          : null,
                      text: FlowyText('Reset to default'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShowUnreadsToggle extends StatelessWidget {
  const _ShowUnreadsToggle({required this.bloc});

  final NotificationFilterBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationFilterBloc>.value(
      value: bloc,
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, state) {
          return Row(
            children: [
              const HSpace(4),
              const Expanded(
                child: FlowyText('Show unreads only'),
              ),
              Toggle(
                style: ToggleStyle.big,
                onChanged: (value) => bloc.add(
                  NotificationFilterEvent.update(
                    showUnreadsOnly: !value,
                  ),
                ),
                value: state.showUnreadsOnly,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupByDateToggle extends StatelessWidget {
  const _GroupByDateToggle({required this.bloc});

  final NotificationFilterBloc bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationFilterBloc>.value(
      value: bloc,
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, state) {
          return Row(
            children: [
              const HSpace(4),
              const Expanded(
                child: FlowyText('Group by date'),
              ),
              Toggle(
                style: ToggleStyle.big,
                onChanged: (value) => bloc.add(
                  NotificationFilterEvent.update(
                    groupByDate: !value,
                  ),
                ),
                value: state.groupByDate,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortByOption extends StatefulWidget {
  const _SortByOption({required this.bloc});

  final NotificationFilterBloc bloc;

  @override
  State<_SortByOption> createState() => _SortByOptionState();
}

class _SortByOptionState extends State<_SortByOption> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationFilterBloc>.value(
      value: widget.bloc,
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, state) {
          final isSortDescending =
              state.sortBy == NotificationSortOption.descending;

          return Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: FlowyText('Sort'),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 115,
                child: FlowyHover(
                  resetHoverOnRebuild: false,
                  child: FlowyButton(
                    onHover: (isHovering) => isHovering != _isHovering
                        ? setState(() => _isHovering = isHovering)
                        : null,
                    onTap: () => widget.bloc.add(
                      NotificationFilterEvent.update(
                        sortBy: isSortDescending
                            ? NotificationSortOption.ascending
                            : NotificationSortOption.descending,
                      ),
                    ),
                    leftIcon: FlowySvg(
                      isSortDescending
                          ? FlowySvgs.sort_descending_s
                          : FlowySvgs.sort_ascending_s,
                      color: _isHovering
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).iconTheme.color,
                    ),
                    text: FlowyText.regular(
                      isSortDescending ? 'Descending' : 'Ascending',
                      color: _isHovering
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
