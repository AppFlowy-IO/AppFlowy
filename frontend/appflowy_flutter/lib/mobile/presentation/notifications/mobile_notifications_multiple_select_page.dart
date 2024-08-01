import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_screen.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNotificationsMultiSelectScreen extends StatelessWidget {
  const MobileNotificationsMultiSelectScreen({super.key});

  static const routeName = '/notifications_multi_select';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: const MobileNotificationMultiSelect(),
    );
  }
}

class MobileNotificationMultiSelect extends StatefulWidget {
  const MobileNotificationMultiSelect({
    super.key,
  });

  @override
  State<MobileNotificationMultiSelect> createState() =>
      _MobileNotificationMultiSelectState();
}

class _MobileNotificationMultiSelectState
    extends State<MobileNotificationMultiSelect> {
  @override
  void dispose() {
    mSelectedNotificationIds.value = [];

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileNotificationMultiSelectPageHeader(),
            VSpace(12.0),
            Expanded(
              child: MultiSelectNotificationTab(),
            ),
          ],
        ),
      ),
    );
  }
}
