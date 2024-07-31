import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/base/gesture.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiSelectNotificationItem extends StatefulWidget {
  const MultiSelectNotificationItem({
    super.key,
    required this.tabType,
    required this.reminder,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;

  @override
  State<MultiSelectNotificationItem> createState() =>
      _MultiSelectNotificationItemState();
}

class _MultiSelectNotificationItemState
    extends State<MultiSelectNotificationItem> {
  final ValueNotifier<bool> isSelected = ValueNotifier(false);

  @override
  void dispose() {
    isSelected.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppearanceSettingsCubit>().state;
    final dateFormate = settings.dateFormat;
    final timeFormate = settings.timeFormat;
    return BlocProvider<NotificationReminderBloc>(
      create: (context) => NotificationReminderBloc()
        ..add(
          NotificationReminderEvent.initial(
            widget.reminder,
            dateFormate,
            timeFormate,
          ),
        ),
      child: BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
        builder: (context, state) {
          if (state.status == NotificationReminderStatus.loading ||
              state.status == NotificationReminderStatus.initial) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationReminderStatus.error) {
            // error handle.
            return const SizedBox.shrink();
          }

          final child = ValueListenableBuilder(
            valueListenable: isSelected,
            builder: (_, isSelected, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: isSelected
                    ? ShapeDecoration(
                        color: const Color(0x1900BCF0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    : null,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _InnerNotificationItem(
                tabType: widget.tabType,
                reminder: widget.reminder,
                isSelected: isSelected,
              ),
            ),
          );

          return AnimatedGestureDetector(
            scaleFactor: 0.99,
            onTapUp: () {
              if (widget.tabType == MobileNotificationTabType.multiSelect) {
                isSelected.value = !isSelected.value;
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}

class _InnerNotificationItem extends StatelessWidget {
  const _InnerNotificationItem({
    required this.reminder,
    required this.tabType,
    required this.isSelected,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;
  final ValueNotifier<bool> isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(10.0),
        NotificationCheckIcon(isSelected: isSelected),
        const HSpace(12.0),
        NotificationIcon(reminder: reminder),
        const HSpace(12.0),
        Expanded(
          child: NotificationContent(reminder: reminder),
        ),
      ],
    );
  }
}
