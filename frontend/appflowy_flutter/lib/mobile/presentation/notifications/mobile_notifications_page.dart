import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/user_profile/user_profile_bloc.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/mobile_notification_tab_bar.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy/workspace/presentation/notifications/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/inbox_action_bar.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_view.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNotificationsScreen extends StatefulWidget {
  const MobileNotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<MobileNotificationsScreen> createState() =>
      _MobileNotificationsScreenState();
}

class _MobileNotificationsScreenState extends State<MobileNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final ReminderBloc _reminderBloc = getIt<ReminderBloc>();
  late final TabController _controller = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserProfileBloc>(
          create: (context) =>
              UserProfileBloc()..add(const UserProfileEvent.started()),
        ),
        BlocProvider<ReminderBloc>.value(value: _reminderBloc),
        BlocProvider<NotificationFilterBloc>(
          create: (_) => NotificationFilterBloc(),
        ),
      ],
      child: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          return state.maybeWhen(
            orElse: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            workspaceFailure: () => const WorkspaceFailedScreen(),
            success: (workspaceSetting, userProfile) =>
                _NotificationScreenContent(
              workspaceSetting: workspaceSetting,
              userProfile: userProfile,
              controller: _controller,
              reminderBloc: _reminderBloc,
            ),
          );
        },
      ),
    );
  }
}

class _NotificationScreenContent extends StatelessWidget {
  const _NotificationScreenContent({
    required this.workspaceSetting,
    required this.userProfile,
    required this.controller,
    required this.reminderBloc,
  });

  final WorkspaceSettingPB workspaceSetting;
  final UserProfilePB userProfile;
  final TabController controller;
  final ReminderBloc reminderBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SidebarSectionsBloc()
        ..add(
          SidebarSectionsEvent.initial(
            userProfile,
            workspaceSetting.workspaceId,
          ),
        ),
      child: BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
        builder: (context, sectionState) =>
            BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
          builder: (context, filterState) =>
              BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              // Workaround for rebuilding the Blocks by brightness
              Theme.of(context).brightness;

              final List<ReminderPB> pastReminders = state.pastReminders
                  .where(
                    (r) => filterState.showUnreadsOnly ? !r.isRead : true,
                  )
                  .sortByScheduledAt();

              final List<ReminderPB> upcomingReminders =
                  state.upcomingReminders.sortByScheduledAt();

              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  title: Text(LocaleKeys.notificationHub_mobile_title.tr()),
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      MobileNotificationTabBar(controller: controller),
                      Expanded(
                        child: TabBarView(
                          controller: controller,
                          children: [
                            NotificationsView(
                              shownReminders: pastReminders,
                              reminderBloc: reminderBloc,
                              views: sectionState.section.publicViews,
                              onAction: _onAction,
                              onDelete: _onDelete,
                              onReadChanged: _onReadChanged,
                              actionBar: InboxActionBar(
                                hasUnreads: state.hasUnreads,
                                showUnreadsOnly: filterState.showUnreadsOnly,
                              ),
                            ),
                            NotificationsView(
                              shownReminders: upcomingReminders,
                              reminderBloc: reminderBloc,
                              views: sectionState.section.publicViews,
                              isUpcoming: true,
                              onAction: _onAction,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onAction(ReminderPB reminder, int? path, ViewPB? view) =>
      reminderBloc.add(
        ReminderEvent.pressReminder(
          reminderId: reminder.id,
          path: path,
          view: view,
        ),
      );

  void _onDelete(ReminderPB reminder) =>
      reminderBloc.add(ReminderEvent.remove(reminderId: reminder.id));

  void _onReadChanged(ReminderPB reminder, bool isRead) => reminderBloc.add(
        ReminderEvent.update(ReminderUpdate(id: reminder.id, isRead: isRead)),
      );
}
