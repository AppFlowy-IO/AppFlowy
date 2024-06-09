import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:collection/collection.dart';

extension ReminderSort on Iterable<ReminderPB> {
  List<ReminderPB> sortByScheduledAt() =>
      sorted((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
}
