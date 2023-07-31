import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:dartz/dartz.dart';

typedef NewLayoutFieldValue = Either<DatabaseLayoutSettingPB, FlowyError>;

class DatabaseCalendarLayoutListener {
  final String viewId;
  PublishNotifier<NewLayoutFieldValue>? _newLayoutFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseCalendarLayoutListener(this.viewId);

  void start({
    required void Function(NewLayoutFieldValue) onCalendarLayoutChanged,
  }) {
    _newLayoutFieldNotifier?.addPublishListener(onCalendarLayoutChanged);
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
      case DatabaseNotification.DidSetNewLayoutField:
        result.fold(
          (payload) => _newLayoutFieldNotifier?.value =
              left(DatabaseLayoutSettingPB.fromBuffer(payload)),
          (error) => _newLayoutFieldNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _newLayoutFieldNotifier?.dispose();
    _newLayoutFieldNotifier = null;
  }
}
