import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum NotificationPaneActionType {
  more,
  archive;

  MobileSlideActionButton actionButton(
    BuildContext context, {
    required MobileNotificationTabType tabType,
  }) {
    switch (this) {
      case NotificationPaneActionType.archive:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFF00C8FF),
          svg: FlowySvgs.more_s,
          size: 24.0,
          onPressed: (context) {
            showToastNotification(
              context,
              message: LocaleKeys
                  .settings_notifications_archiveNotifications_success
                  .tr(),
            );

            context.read<ReminderBloc>().add(
                  ReminderEvent.update(
                    ReminderUpdate(
                      id: context.read<NotificationReminderBloc>().reminder.id,
                      isArchived: true,
                      isRead: true,
                    ),
                  ),
                );
          },
        );
      case NotificationPaneActionType.more:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xE5515563),
          svg: FlowySvgs.three_dots_s,
          size: 24.0,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
          onPressed: (context) {
            final viewBloc = context.read<ViewBloc>();
            final favoriteBloc = context.read<FavoriteBloc>();
            final recentViewsBloc = context.read<RecentViewsBloc?>();
            showMobileBottomSheet(
              context,
              showDragHandle: true,
              showDivider: false,
              useRootNavigator: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: viewBloc),
                    BlocProvider.value(value: favoriteBloc),
                    if (recentViewsBloc != null)
                      BlocProvider.value(value: recentViewsBloc),
                  ],
                  child: BlocBuilder<ViewBloc, ViewState>(
                    builder: (context, state) {
                      // show menu
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            );
          },
        );
    }
  }
}

ActionPane buildNotificationEndActionPane(
  BuildContext context,
  List<NotificationPaneActionType> actions, {
  required MobileNotificationTabType tabType,
  required double spaceRatio,
}) {
  return ActionPane(
    motion: const ScrollMotion(),
    extentRatio: actions.length / spaceRatio,
    children: [
      ...actions.map(
        (action) => action.actionButton(
          context,
          tabType: tabType,
        ),
      ),
    ],
  );
}
