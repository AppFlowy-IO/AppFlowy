import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef LayoutSettingsValue<T> = FlowyResult<T, FlowyError>;

class DatabaseLayoutSettingListener {
  DatabaseLayoutSettingListener(this.viewId);

  final String viewId;

  PublishNotifier<LayoutSettingsValue<DatabaseLayoutSettingPB>>?
      _settingNotifier = PublishNotifier();
  DatabaseNotificationListener? _listener;

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
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateLayoutSettings:
        result.fold(
          (payload) => _settingNotifier?.value =
              FlowyResult.success(DatabaseLayoutSettingPB.fromBuffer(payload)),
          (error) => _settingNotifier?.value = FlowyResult.failure(error),
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
