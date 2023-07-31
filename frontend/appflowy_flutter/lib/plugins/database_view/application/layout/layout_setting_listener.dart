import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:dartz/dartz.dart';

typedef LayoutSettingsValue<T> = Either<T, FlowyError>;

class DatabaseLayoutSettingListener {
  final String viewId;
  PublishNotifier<LayoutSettingsValue<DatabaseLayoutSettingPB>>?
      _settingNotifier = PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseLayoutSettingListener(this.viewId);

  void start({
    required void Function(LayoutSettingsValue<DatabaseLayoutSettingPB>)
        onLayoutChanged,
  }) {
    _settingNotifier?.addPublishListener(onLayoutChanged);
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
      case DatabaseNotification.DidUpdateLayoutSettings:
        result.fold(
          (payload) => _settingNotifier?.value =
              left(DatabaseLayoutSettingPB.fromBuffer(payload)),
          (error) => _settingNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _settingNotifier?.dispose();
    _settingNotifier = null;
  }
}
