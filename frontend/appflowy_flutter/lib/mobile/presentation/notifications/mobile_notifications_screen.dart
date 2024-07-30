import 'package:appflowy/mobile/application/user_profile/user_profile_bloc.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNotificationsScreenV2 extends StatefulWidget {
  const MobileNotificationsScreenV2({super.key});

  static const routeName = '/notifications';

  @override
  State<MobileNotificationsScreenV2> createState() =>
      _MobileNotificationsScreenV2State();
}

class _MobileNotificationsScreenV2State
    extends State<MobileNotificationsScreenV2>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserProfileBloc>(
          create: (context) =>
              UserProfileBloc()..add(const UserProfileEvent.started()),
        ),
        BlocProvider<ReminderBloc>.value(value: getIt<ReminderBloc>()),
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
                const MobileNotificationsTab(),
          );
        },
      ),
    );
  }
}

class MobileNotificationsTab extends StatefulWidget {
  const MobileNotificationsTab({
    super.key,
    // required this.userProfile,
  });

  // final UserProfilePB userProfile;

  @override
  State<MobileNotificationsTab> createState() => _MobileNotificationsTabState();
}

class _MobileNotificationsTabState extends State<MobileNotificationsTab>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final tabs = [
    MobileNotificationTabType.inbox,
    MobileNotificationTabType.unread,
    MobileNotificationTabType.archive,
  ];

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 3,
      vsync: this,
    );
    tabController.addListener(_onTabChange);
  }

  @override
  void dispose() {
    tabController.removeListener(_onTabChange);
    tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MobileNotificationPageHeader(),
            MobileNotificationTabBar(
              tabController: tabController,
              tabs: tabs,
            ),
            const VSpace(12.0),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: tabs.map((e) => NotificationTab(tabType: e)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabChange() {}
}
