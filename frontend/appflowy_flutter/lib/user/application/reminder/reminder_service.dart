import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Interface for a Reminder Service that handles
/// communication to the backend
///
abstract class IReminderService {
  Future<FlowyResult<List<ReminderPB>, FlowyError>> fetchReminders();

  Future<FlowyResult<void, FlowyError>> removeReminder({
    required String reminderId,
  });

  Future<FlowyResult<void, FlowyError>> addReminder({
    required ReminderPB reminder,
  });

  Future<FlowyResult<void, FlowyError>> updateReminder({
    required ReminderPB reminder,
  });
}

class ReminderService implements IReminderService {
  const ReminderService();

  @override
  Future<FlowyResult<void, FlowyError>> addReminder({
    required ReminderPB reminder,
  }) async {
    final unitOrFailure = await UserEventCreateReminder(reminder).send();

    return unitOrFailure;
  }

  @override
  Future<FlowyResult<void, FlowyError>> updateReminder({
    required ReminderPB reminder,
  }) async {
    final unitOrFailure = await UserEventUpdateReminder(reminder).send();

    return unitOrFailure;
  }

  @override
  Future<FlowyResult<List<ReminderPB>, FlowyError>> fetchReminders() async {
    final resultOrFailure = await UserEventGetAllReminders().send();

    return resultOrFailure.fold(
      (s) => FlowyResult.success(s.items),
      (e) => FlowyResult.failure(e),
    );
  }

  @override
  Future<FlowyResult<void, FlowyError>> removeReminder({
    required String reminderId,
  }) async {
    final request = ReminderIdentifierPB(id: reminderId);
    final unitOrFailure = await UserEventRemoveReminder(request).send();

    return unitOrFailure;
  }
}
