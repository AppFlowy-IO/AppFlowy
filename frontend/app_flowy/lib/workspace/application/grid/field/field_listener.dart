import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';

typedef UpdateFieldNotifiedValue = Either<Field, FlowyError>;

class SingleFieldListener {
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue>? _updateFieldNotifier = PublishNotifier();
  GridNotificationListener? _listener;

  SingleFieldListener({required this.fieldId});

  void start({required void Function(UpdateFieldNotifiedValue) onFieldChanged}) {
    _updateFieldNotifier?.addPublishListener(onFieldChanged);
    _listener = GridNotificationListener(
      objectId: fieldId,
      handler: _handler,
    );
  }

  void _handler(
    GridNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridNotification.DidUpdateField:
        result.fold(
          (payload) => _updateFieldNotifier?.value = left(Field.fromBuffer(payload)),
          (error) => _updateFieldNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateFieldNotifier?.dispose();
    _updateFieldNotifier = null;
  }
}
