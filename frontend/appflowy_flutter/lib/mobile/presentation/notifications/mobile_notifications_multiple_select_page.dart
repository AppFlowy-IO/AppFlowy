import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileNotificationsMultiSelectScreen extends StatefulWidget {
  const MobileNotificationsMultiSelectScreen({super.key});

  static const routeName = '/notifications_multi_select';

  @override
  State<MobileNotificationsMultiSelectScreen> createState() =>
      _MobileNotificationsMultiSelectScreenState();
}

class _MobileNotificationsMultiSelectScreenState
    extends State<MobileNotificationsMultiSelectScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: const _NotificationMultiSelect(),
    );
  }
}

class _NotificationMultiSelect extends StatefulWidget {
  const _NotificationMultiSelect();

  @override
  State<_NotificationMultiSelect> createState() =>
      _NotificationMultiSelectState();
}

class _NotificationMultiSelectState extends State<_NotificationMultiSelect> {
  final ValueNotifier<int> selectedCount = ValueNotifier(0);

  @override
  void dispose() {
    selectedCount.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MobileNotificationMultiSelectPageHeader(
              selectedCount: selectedCount,
            ),
          ],
        ),
      ),
    );
  }
}
