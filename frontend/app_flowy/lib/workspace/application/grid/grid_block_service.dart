import 'dart:collection';
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

import 'grid_service.dart';

typedef DidLoadRowsCallback = void Function(List<GridRowData>);
typedef GridBlockUpdateNotifiedValue = Either<GridBlockId, FlowyError>;

class GridBlockService {
  String gridId;
  List<Field> fields;
  LinkedHashMap<String, GridBlock> blockMap = LinkedHashMap();
  late GridBlockListener _blockListener;
  DidLoadRowsCallback? didLoadRowscallback;

  GridBlockService({required this.gridId, required this.fields, required List<GridBlock> gridBlocks}) {
    for (final gridBlock in gridBlocks) {
      blockMap[gridBlock.blockId] = gridBlock;
    }

    _blockListener = GridBlockListener(gridId: gridId);
    _blockListener.blockUpdateNotifier.addPublishListener((result) {
      result.fold((blockId) {
        //
      }, (err) => null);
    });
  }

  List<GridRowData> rows() {
    List<GridRowData> rows = [];
    blockMap.forEach((_, gridBlock) {
      rows.addAll(gridBlock.rowIds.map(
        (rowId) => GridRowData(
          gridId: gridId,
          fields: fields,
          blockId: gridBlock.blockId,
          rowId: rowId,
        ),
      ));
    });
    return rows;
  }

  Future<void> stop() async {
    await _blockListener.stop();
  }
}

class GridBlockListener {
  final String gridId;
  PublishNotifier<GridBlockUpdateNotifiedValue> blockUpdateNotifier = PublishNotifier<GridBlockUpdateNotifiedValue>();
  StreamSubscription<SubscribeObject>? _subscription;
  late GridNotificationParser _parser;

  GridBlockListener({required this.gridId});

  void start() {
    _parser = GridNotificationParser(
      id: gridId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser.parse(observable));
  }

  void _handleObservableType(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.GridDidUpdateBlock:
        result.fold(
          (payload) => blockUpdateNotifier.value = left(GridBlockId.fromBuffer(payload)),
          (error) => blockUpdateNotifier.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    blockUpdateNotifier.dispose();
  }
}
