import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef FieldSettingsValue = FlowyResult<FieldSettingsPB, FlowyError>;

class FieldSettingsListener {
  FieldSettingsListener({required this.viewId});

  final String viewId;

  PublishNotifier<FieldSettingsValue>? _fieldSettingsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;

  void start({
    required void Function(FieldSettingsValue) onFieldSettingsChanged,
  }) {
    _fieldSettingsNotifier?.addPublishListener(onFieldSettingsChanged);
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
      case DatabaseNotification.DidUpdateFieldSettings:
        result.fold(
          (payload) => _fieldSettingsNotifier?.value =
              FlowyResult.success(FieldSettingsPB.fromBuffer(payload)),
          (error) => _fieldSettingsNotifier?.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _fieldSettingsNotifier?.dispose();
    _fieldSettingsNotifier = null;
  }
}
