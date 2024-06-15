import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/background_task_notification/background_task_notification_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tasknotification.dart';

class BackGroundTaskNotifactionBox extends StatefulWidget {
  BackGroundTaskNotifactionBox();

  @override
  State<BackGroundTaskNotifactionBox> createState() =>
      _BackGroundTaskNotifactionBoxState();
}

class _BackGroundTaskNotifactionBoxState
    extends State<BackGroundTaskNotifactionBox> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackgroundTaskNotificationBloc,
        BackgroundTaskNotificationState>(
      bloc: context.read<BackgroundTaskNotificationBloc>(),
      builder: (context, state) {
        print("stae: ${state}");
        if (state.taskNotifications.isEmpty) {
          // Return an empty SizedBox if there are no task notifications
          print("NO task notifications");
          return SizedBox.shrink();
        } else {
          return Container(
            constraints: const BoxConstraints(
              maxHeight: 200,
              minWidth: double.infinity,
            ),
            color: Colors.transparent,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.taskNotifications.length,
              itemBuilder: (context, index) {
                final taskNotification = state.taskNotifications[index];
                return TaskNotificationWidget(taskNotification: taskNotification);
              },
            ),
          );
        }
      },
    );
  }
}

class TaskActionButton extends StatefulWidget {
  TaskActionButton({
    super.key,
    required this.buttontext,
    required this.task,
    required this.buttonTextColor,
  });
  String buttontext;
  TaskNotification task;
  Color buttonTextColor;

  @override
  State<TaskActionButton> createState() => _TaskActionButtonState();
}

class _TaskActionButtonState extends State<TaskActionButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.task.status == TaskStatus.inProgress) {
          getIt<BackgroundTaskNotificationBloc>().add(
              BackgroundTaskNotificationEvent.taskCancelled(
                  taskID: widget.task.taskId));
        } else if (widget.task.status == TaskStatus.completed) {
          getIt<BackgroundTaskNotificationBloc>().add(
              BackgroundTaskNotificationEvent.removeTaskFromList(
                  taskID: widget.task.taskId));
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: FlowyText(
          widget.buttontext,
          color: widget.buttonTextColor,
          fontWeight: FontWeight.bold,
          decoration: _isHovered
              ? TextDecoration.underline
              : TextDecoration.none,

        ),
      ),
    );
  }
}
