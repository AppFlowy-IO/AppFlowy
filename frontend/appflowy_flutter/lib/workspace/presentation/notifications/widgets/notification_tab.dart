import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/empty.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_item_v2.dart';
import 'notification_tab_bar.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({
    super.key,
    required this.tabType,
  });

  final NotificationTabType tabType;

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final reminders = _filterReminders(state.reminders);

        if (reminders.isEmpty) return EmptyNotification(type: widget.tabType);

        final dateTimeNow = DateTime.now();
        final List<ReminderPB> todayReminders = [];
        final List<ReminderPB> olderReminders = [];
        for (final reminder in reminders) {
          final scheduledAt = reminder.scheduledAt.toDateTime();
          if (dateTimeNow.difference(scheduledAt).inDays < 1) {
            todayReminders.add(reminder);
          } else {
            olderReminders.add(reminder);
          }
        }

        final child = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildReminders(
                LocaleKeys.notificationHub_today.tr(),
                todayReminders,
              ),
              buildReminders(
                LocaleKeys.notificationHub_older.tr(),
                olderReminders,
              ),
            ],
          ),
        );

        return RefreshIndicator.adaptive(
          onRefresh: () async => _onRefresh(context),
          child: child,
        );
      },
    );
  }

  Widget buildReminders(
    String title,
    List<ReminderPB> reminders,
  ) {
    if (reminders.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FlowyText.regular(
            title,
            fontSize: 14,
            figmaLineHeight: 18,
          ),
        ),
        const VSpace(4),
        ...List.generate(reminders.length, (index) {
          final reminder = reminders[index];
          return NotificationItemV2(
            key: ValueKey('${widget.tabType}_${reminder.id}'),
            tabType: widget.tabType,
            reminder: reminder,
          );
        }),
      ],
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<ReminderBloc>().add(const ReminderEvent.refresh());

    // at least 0.5 seconds to dismiss the refresh indicator.
    // otherwise, it will be dismissed immediately.
    await context.read<ReminderBloc>().stream.firstOrNull;
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      showToastNotification(
        message: LocaleKeys.settings_notifications_refreshSuccess.tr(),
      );
    }
  }

  List<ReminderPB> _filterReminders(List<ReminderPB> reminders) {
    switch (widget.tabType) {
      case NotificationTabType.inbox:
        return reminders.reversed
            .where((reminder) => !reminder.isArchived)
            .toList()
            .unique((reminder) => reminder.id);
      case NotificationTabType.archive:
        return reminders.reversed
            .where((reminder) => reminder.isArchived)
            .toList()
            .unique((reminder) => reminder.id);
      case NotificationTabType.unread:
        return reminders.reversed
            .where((reminder) => !reminder.isRead)
            .toList()
            .unique((reminder) => reminder.id);
    }
  }
}
