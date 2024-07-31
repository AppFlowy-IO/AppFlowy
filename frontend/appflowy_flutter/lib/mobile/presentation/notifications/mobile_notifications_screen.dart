import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_multiple_select_page.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: ValueListenableBuilder(
        valueListenable: bottomNavigationBarType,
        builder: (_, value, __) {
          switch (value) {
            case BottomNavigationBarActionType.home:
              return const MobileNotificationsTab();
            case BottomNavigationBarActionType.notificationMultiSelect:
              return const MobileNotificationMultiSelect();
          }
        },
      ),
    );
  }
}

class MobileNotificationsTab extends StatefulWidget {
  const MobileNotificationsTab({
    super.key,
  });

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
  }

  @override
  void dispose() {
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
}
