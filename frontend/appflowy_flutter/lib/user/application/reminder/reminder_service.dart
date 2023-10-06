import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:dartz/dartz.dart';

/// Interface for a Reminder Service that handles
/// communication to the backend
///
abstract class IReminderService {
  Future<Either<FlowyError, List<ReminderPB>>> fetchReminders();

  Future<Either<FlowyError, Unit>> removeReminder({required String reminderId});

  Future<Either<FlowyError, Unit>> addReminder({required ReminderPB reminder});

  Future<Either<FlowyError, Unit>> updateReminder({
    required ReminderPB reminder,
  });
}

class ReminderService implements IReminderService {
  const ReminderService();

  @override
  Future<Either<FlowyError, Unit>> addReminder({
    required ReminderPB reminder,
  }) async {
    final unitOrFailure = await UserEventCreateReminder(reminder).send();

    return unitOrFailure.swap();
  }

  @override
  Future<Either<FlowyError, Unit>> updateReminder({
    required ReminderPB reminder,
  }) async {
    final unitOrFailure = await UserEventUpdateReminder(reminder).send();

    return unitOrFailure.swap();
  }

  @override
  Future<Either<FlowyError, List<ReminderPB>>> fetchReminders() async {
    final resultOrFailure = await UserEventGetAllReminders().send();

    return resultOrFailure.swap().fold((l) => left(l), (r) => right(r.items));
  }

  @override
  Future<Either<FlowyError, Unit>> removeReminder({
    required String reminderId,
  }) async {
    final request = ReminderIdentifierPB(id: reminderId);
    final unitOrFailure = await UserEventRemoveReminder(request).send();

    return unitOrFailure.swap();
  }
}
