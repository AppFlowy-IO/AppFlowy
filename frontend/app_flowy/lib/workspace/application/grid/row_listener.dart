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

typedef UpdateCellNotifiedValue = Either<RepeatedCell, FlowyError>;
typedef UpdateRowNotifiedValue = Either<Row, FlowyError>;

class RowListener {
  final String rowId;
  PublishNotifier<UpdateCellNotifiedValue> updateCellNotifier = PublishNotifier<UpdateCellNotifiedValue>();
  PublishNotifier<UpdateRowNotifiedValue> updateRowNotifier = PublishNotifier<UpdateRowNotifiedValue>();
  StreamSubscription<SubscribeObject>? _subscription;
  late GridNotificationParser _parser;

  RowListener({required this.rowId});

  void start() {
    _parser = GridNotificationParser(
      id: rowId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.GridDidUpdateCells:
        result.fold(
          (payload) => updateCellNotifier.value = left(RepeatedCell.fromBuffer(payload)),
          (error) => updateCellNotifier.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    updateCellNotifier.dispose();
    updateRowNotifier.dispose();
  }
}
