import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';

typedef UpdateFieldNotifiedValue = Either<GridFieldChangeset, FlowyError>;

class GridFieldsListener {
  final String gridId;
  PublishNotifier<UpdateFieldNotifiedValue> updateFieldsNotifier = PublishNotifier();
  GridNotificationListener? _listener;
  GridFieldsListener({required this.gridId});

  void start() {
    _listener = GridNotificationListener(
      objectId: gridId,
      handler: _handler,
    );
  }

  void _handler(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateGridField:
        result.fold(
          (payload) => updateFieldsNotifier.value = left(GridFieldChangeset.fromBuffer(payload)),
          (error) => updateFieldsNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    updateFieldsNotifier.dispose();
  }
}
