import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:dartz/dartz.dart';

typedef CalendarSettingsValue = Either<CalendarSettingsPB, FlowyError>;
typedef ArrangeWithNewField = Either<FieldPB, FlowyError>;

class CalendarListener {
  final String viewId;
  PublishNotifier<CalendarSettingsValue>? _calendarSettingsNotifier =
      PublishNotifier();
  PublishNotifier<ArrangeWithNewField>? _arrangeWithNewFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  CalendarListener(this.viewId);

  void start({
    required void Function(CalendarSettingsValue) onCalendarSettingsChanged,
    required void Function(ArrangeWithNewField) onArrangeWithNewField,
  }) {
    _calendarSettingsNotifier?.addPublishListener(onCalendarSettingsChanged);
    _arrangeWithNewFieldNotifier?.addPublishListener(onArrangeWithNewField);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateCalendarSettings:
        result.fold(
          (payload) => _calendarSettingsNotifier?.value =
              left(CalendarSettingsPB.fromBuffer(payload)),
          (error) => _calendarSettingsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidArrangeCalendarWithNewField:
        result.fold(
          (payload) => _arrangeWithNewFieldNotifier?.value =
              left(FieldPB.fromBuffer(payload)),
          (error) => _arrangeWithNewFieldNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _calendarSettingsNotifier?.dispose();
    _calendarSettingsNotifier = null;

    _arrangeWithNewFieldNotifier?.dispose();
    _arrangeWithNewFieldNotifier = null;
  }
}
