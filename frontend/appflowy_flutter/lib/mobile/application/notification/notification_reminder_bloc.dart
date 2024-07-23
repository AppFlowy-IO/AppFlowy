import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:provider/provider.dart';
import 'package:time/time.dart';

part 'notification_reminder_bloc.freezed.dart';

class NotificationReminderBloc
    extends Bloc<NotificationReminderEvent, NotificationReminderState> {
  NotificationReminderBloc() : super(NotificationReminderState.initial()) {
    on<NotificationReminderEvent>((event, emit) async {
      event.when(
        initial: (reminder) {
          final createdAt = reminder.createdAt;
        },
        reset: () => emit(const NotificationReminderState()),
      );
    });
  }

  String _formatTimestamp(int timestamp) {
    final now = DateTime.now();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(dateTime);
    final String date;

    if (difference.inMinutes < 1) {
      date = LocaleKeys.sideBar_justNow.tr();
    } else if (difference.inHours < 1 && dateTime.isToday) {
      // Less than 1 hour
      date = LocaleKeys.sideBar_minutesAgo
          .tr(namedArgs: {'count': difference.inMinutes.toString()});
    } else if (difference.inHours >= 1 && dateTime.isToday) {
      // in same day
      date = timeFormat.formatTime(dateTime);
    } else {
      date = dateFormate.formatDate(dateTime, false);
    }

    if (difference.inHours >= 1) {
      return '${type.lastOperationHintText} $date';
    }

    return date;
  }
}

@freezed
class NotificationReminderEvent with _$NotificationReminderEvent {
  const factory NotificationReminderEvent.initial(ReminderPB reminder) =
      _Initial;

  const factory NotificationReminderEvent.reset() = _Reset;
}

enum NotificationReminderStatus {
  initial,
  loading,
  loaded,
}

@freezed
class NotificationReminderState with _$NotificationReminderState {
  const NotificationReminderState._();

  const factory NotificationReminderState({
    required String createdAt,
    required String pageTitle,
    required String reminderContent,
    @Default(NotificationReminderStatus.initial)
    required NotificationReminderStatus status,
  }) = _NotificationReminderState;

  factory NotificationReminderState.initial() =>
      const NotificationReminderState(
        createdAt: '',
        pageTitle: '',
        reminderContent: '',
      );
}
