import 'dart:async';

import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nanoid/nanoid.dart';
import 'package:equatable/equatable.dart';
part 'background_task_notification_bloc.freezed.dart';

class Task {
  Task({
    required this.onCancel,
    required this.displayMessage,
    required this.taskFunction,
    required this.args,
  }) : taskId = nanoid();

  final Function taskFunction;
  final List<dynamic> args;
  final Function onCancel;
  final String displayMessage;
  final String taskId; // Unique task ID
}

enum TaskStatus {
  completed,
  cancelled,
  inProgress,
}

class TaskNotificationList extends Equatable {
  final List<TaskNotification> taskNotifications;
  TaskNotificationList(this.taskNotifications);
  @override
  List<Object?> get props => [taskNotifications];
}

class TaskNotification extends Equatable {
  TaskNotification({
    required this.message,
    required this.status,
    required this.taskId,
  });
  String message;
  TaskStatus status;
  String taskId;
  @override
  List<Object?> get props => [message, status, taskId];
}

class BackgroundTaskNotificationBloc extends Bloc<
    BackgroundTaskNotificationEvent, BackgroundTaskNotificationState> {
  BackgroundTaskNotificationBloc()
      : super(BackgroundTaskNotificationState.initial()) {
    on<BackgroundTaskNotificationEvent>((event, emit) async {
      await event.when(
        addNewTask: (e) async {
          final task = e;
          final taskNotification = TaskNotification(
            message: task.displayMessage,
            status: TaskStatus.inProgress,
            taskId: task.taskId,
          );
          final List<TaskNotification> newTaskNotifications = [
            ...state.taskNotifications,
            taskNotification
          ];
          emit(
            state.copyWith(
              taskNotifications: newTaskNotifications,
            ),
          );
          print("**** ADD NEW TASK *** $state");
          _streamController.add(task);
        },
        taskCompleted: (e) async {
          final taskID = e;
          final List<TaskNotification> updatedTaskNotifications = [];

          for (final taskNotification in state.taskNotifications) {
            if (taskNotification.taskId == taskID) {
              updatedTaskNotifications.add(TaskNotification(
                  message: taskNotification.message,
                  status: TaskStatus.completed,
                  taskId: taskNotification.taskId));
            } else {
              updatedTaskNotifications.add(taskNotification);
            }
          }

          emit(
            state.copyWith(taskNotifications: updatedTaskNotifications),
          );
          print("**** TASK COMPLETED *** $state");
        },
        taskCancelled: (e) async {
          final taskID = e;
          cancelTask(taskID);
          final List<TaskNotification> updatedTaskNotifications = [];

          for (final taskNotification in state.taskNotifications) {
            if (taskNotification.taskId == taskID) {
              updatedTaskNotifications.add(
                TaskNotification(
                  message: taskNotification.message,
                  status: TaskStatus.cancelled,
                  taskId: taskNotification.taskId,
                ),
              );
            } else {
              updatedTaskNotifications.add(taskNotification);
            }
          }


          emit(
            state.copyWith(taskNotifications: updatedTaskNotifications),
          );
        },
        removeTaskFromList: (e) async {
          final taskID = e;
          final List<TaskNotification> updatedTaskNotifications = [];

          for (final taskNotification in state.taskNotifications) {
            if (taskNotification.taskId != taskID) {
              updatedTaskNotifications.add(taskNotification);
            }
          }

          emit(
            state.copyWith(taskNotifications: updatedTaskNotifications),
          );
        },
      );
    });
    startNotificationStream();
  }
  final _streamController = StreamController<Task>.broadcast();
  Stream<Task> get dataStream => _streamController.stream;
  final operations = <String, CancelableOperation<void>>{};
  void startNotificationStream() {
    dataStream.listen((event) {
      final List<dynamic> functionArgs = event.args;
      final completer = CancelableCompleter();
      functionArgs.add(completer);
      final operation = CancelableOperation.fromFuture(
        Function.apply(event.taskFunction, functionArgs),
        onCancel: ()=>completer.operation.cancel(),
      );
      
      operations[event.taskId] = operation;
      operation.value.then((value) {
        add(
          BackgroundTaskNotificationEvent.taskCompleted(
            taskID: event.taskId,
          ),
        );
      }).catchError((error) {
        //TODO: add erro rstate
        print("****** ERRO R IN BLOC BACKGROUNF TASK **");
        add(
          BackgroundTaskNotificationEvent.taskCancelled(
            taskID: event.taskId,
          ),
        );
      });
    });
  }

  void cancelTask(String taskId) {
    final task = operations[taskId];
    if (task != null) {
      task.cancel();
    }
  }

  @override
  Future<void> close() async {
    print("*** CANCEL EVENT *** NOOOOO!!!!");
    await _streamController.close(); // Close the stream controller
    await super.close(); // Call the parent close method
  }
}

@freezed
class BackgroundTaskNotificationEvent with _$BackgroundTaskNotificationEvent {
  const factory BackgroundTaskNotificationEvent.addNewTask(
      {required Task task}) = AddNewTask;
  const factory BackgroundTaskNotificationEvent.taskCompleted(
      {required String taskID}) = TaskCompleted;
  const factory BackgroundTaskNotificationEvent.taskCancelled(
      {required String taskID}) = TaskCancelled;
  const factory BackgroundTaskNotificationEvent.removeTaskFromList(
      {required String taskID}) = RemoveTaskFromList;
}

@freezed
class BackgroundTaskNotificationState with _$BackgroundTaskNotificationState {
  const factory BackgroundTaskNotificationState(
          {required List<TaskNotification> taskNotifications}) =
      _BackgroundTaskNotificationState;

  factory BackgroundTaskNotificationState.initial() =>
      const BackgroundTaskNotificationState(
        taskNotifications: [],
      );
}
