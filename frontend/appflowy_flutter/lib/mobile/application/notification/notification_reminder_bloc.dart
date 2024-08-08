import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/date_time/time_format_ext.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:time/time.dart';

part 'notification_reminder_bloc.freezed.dart';

class NotificationReminderBloc
    extends Bloc<NotificationReminderEvent, NotificationReminderState> {
  NotificationReminderBloc() : super(NotificationReminderState.initial()) {
    on<NotificationReminderEvent>((event, emit) async {
      await event.when(
        initial: (reminder, dateFormat, timeFormat) async {
          this.reminder = reminder;
          this.dateFormat = dateFormat;
          this.timeFormat = timeFormat;

          add(const NotificationReminderEvent.reset());
        },
        reset: () async {
          final createdAt = await _getCreatedAt(
            reminder,
            dateFormat,
            timeFormat,
          );
          final view = await _getView(reminder);

          if (view == null) {
            emit(
              NotificationReminderState(
                createdAt: createdAt,
                pageTitle: '',
                reminderContent: '',
                status: NotificationReminderStatus.error,
              ),
            );
          }

          final layout = view!.layout;

          if (layout.isDocumentView) {
            final node = await _getContent(reminder);
            if (node != null) {
              emit(
                NotificationReminderState(
                  createdAt: createdAt,
                  pageTitle: view.name,
                  view: view,
                  reminderContent: node.delta?.toPlainText() ?? '',
                  nodes: [node],
                  status: NotificationReminderStatus.loaded,
                ),
              );
            }
          } else if (layout.isDatabaseView) {
            emit(
              NotificationReminderState(
                createdAt: createdAt,
                pageTitle: view.name,
                view: view,
                reminderContent: reminder.message,
                status: NotificationReminderStatus.loaded,
              ),
            );
          }
        },
      );
    });
  }

  late final ReminderPB reminder;
  late final UserDateFormatPB dateFormat;
  late final UserTimeFormatPB timeFormat;

  Future<String> _getCreatedAt(
    ReminderPB reminder,
    UserDateFormatPB dateFormat,
    UserTimeFormatPB timeFormat,
  ) async {
    final rCreatedAt = reminder.createdAt;
    final createdAt = rCreatedAt != null
        ? _formatTimestamp(
            rCreatedAt,
            timeFormat: timeFormat,
            dateFormate: dateFormat,
          )
        : '';
    return createdAt;
  }

  Future<ViewPB?> _getView(ReminderPB reminder) async {
    return ViewBackendService.getView(reminder.objectId)
        .fold((s) => s, (_) => null);
  }

  Future<Node?> _getContent(ReminderPB reminder) async {
    final blockId = reminder.meta[ReminderMetaKeys.blockId];

    if (blockId == null) {
      return null;
    }

    final document = await DocumentService()
        .openDocument(
          documentId: reminder.objectId,
        )
        .fold((s) => s.toDocument(), (_) => null);

    if (document == null) {
      return null;
    }

    final node = _searchById(document.root, blockId);

    if (node == null) {
      return null;
    }

    return node;
  }

  Node? _searchById(Node current, String id) {
    if (current.id == id) {
      return current;
    }

    if (current.children.isNotEmpty) {
      for (final child in current.children) {
        final node = _searchById(child, id);

        if (node != null) {
          return node;
        }
      }
    }

    return null;
  }

  String _formatTimestamp(
    int timestamp, {
    required UserDateFormatPB dateFormate,
    required UserTimeFormatPB timeFormat,
  }) {
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

    return date;
  }
}

@freezed
class NotificationReminderEvent with _$NotificationReminderEvent {
  const factory NotificationReminderEvent.initial(
    ReminderPB reminder,
    UserDateFormatPB dateFormat,
    UserTimeFormatPB timeFormat,
  ) = _Initial;

  const factory NotificationReminderEvent.reset() = _Reset;
}

enum NotificationReminderStatus {
  initial,
  loading,
  loaded,
  error,
}

@freezed
class NotificationReminderState with _$NotificationReminderState {
  const NotificationReminderState._();

  const factory NotificationReminderState({
    required String createdAt,
    required String pageTitle,
    required String reminderContent,
    @Default(NotificationReminderStatus.initial)
    NotificationReminderStatus status,
    @Default([]) List<Node> nodes,
    ViewPB? view,
  }) = _NotificationReminderState;

  factory NotificationReminderState.initial() =>
      const NotificationReminderState(
        createdAt: '',
        pageTitle: '',
        reminderContent: '',
      );
}
