import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';

typedef UpdateFieldNotifiedValue = Either<Field, FlowyError>;

class FieldListener {
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue> updateFieldNotifier = PublishNotifier();
  StreamSubscription<SubscribeObject>? _subscription;
  GridNotificationParser? _parser;

  FieldListener({required this.fieldId});

  void start() {
    _parser = GridNotificationParser(
      id: fieldId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleObservableType(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateField:
        result.fold(
          (payload) => updateFieldNotifier.value = left(Field.fromBuffer(payload)),
          (error) => updateFieldNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    updateFieldNotifier.dispose();
  }
}
