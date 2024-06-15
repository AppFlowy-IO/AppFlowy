import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/sidebar/background_task_notification/background_task_notification_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class TaskNotificationWidget extends StatelessWidget {
  const TaskNotificationWidget({super.key, required this.taskNotification});
  final TaskNotification taskNotification;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Theme.of(context).colorScheme.background,
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    child: Text(
                      taskNotification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: taskNotification.status == TaskStatus.inProgress
                        ? TaskActionButton(
                            buttontext: 'Cancel',
                            task: taskNotification,
                            buttonTextColor:
                                Theme.of(context).colorScheme.primary,
                          )
                        : TaskActionButton(
                            buttontext: 'Remove',
                            task: taskNotification,
                            buttonTextColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: taskNotification.status == TaskStatus.inProgress
                  ? const CircularProgressIndicator()
                  : taskNotification.status == TaskStatus.completed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskActionButton extends StatefulWidget {
  const TaskActionButton({
    super.key,
    required this.buttontext,
    required this.task,
    required this.buttonTextColor,
  });
  final String buttontext;
  final TaskNotification task;
  final Color buttonTextColor;

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
              taskID: widget.task.taskId,
            ),
          );
        } else {
          getIt<BackgroundTaskNotificationBloc>().add(
            BackgroundTaskNotificationEvent.removeTaskFromList(
              taskID: widget.task.taskId,
            ),
          );
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: FlowyText(
          widget.buttontext,
          color: widget.buttonTextColor,
          fontWeight: FontWeight.bold,
          decoration:
              _isHovered ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }
}
