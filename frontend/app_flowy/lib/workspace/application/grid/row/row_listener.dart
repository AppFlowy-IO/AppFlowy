import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';
import 'package:dartz/dartz.dart';

typedef UpdateRowNotifiedValue = Either<Row, FlowyError>;
typedef UpdateFieldNotifiedValue = Either<List<Field>, FlowyError>;

class RowListener {
  final String rowId;
  PublishNotifier<UpdateRowNotifiedValue> updateRowNotifier = PublishNotifier();
  StreamSubscription<SubscribeObject>? _subscription;
  GridNotificationParser? _parser;

  RowListener({required this.rowId});

  void start() {
    _parser = GridNotificationParser(
      id: rowId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleObservableType(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateRow:
        result.fold(
          (payload) => updateRowNotifier.value = left(Row.fromBuffer(payload)),
          (error) => updateRowNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    updateRowNotifier.dispose();
  }
}
