import 'package:app_flowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';

typedef UpdateFieldNotifiedValue = Either<FieldPB, FlowyError>;

class SingleFieldListener {
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue>? _updateFieldNotifier =
      PublishNotifier();
  GridNotificationListener? _listener;

  SingleFieldListener({required this.fieldId});

  void start(
      {required void Function(UpdateFieldNotifiedValue) onFieldChanged}) {
    _updateFieldNotifier?.addPublishListener(onFieldChanged);
    _listener = GridNotificationListener(
      objectId: fieldId,
      handler: _handler,
    );
  }

  void _handler(
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateField:
        result.fold(
          (payload) =>
              _updateFieldNotifier?.value = left(FieldPB.fromBuffer(payload)),
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
