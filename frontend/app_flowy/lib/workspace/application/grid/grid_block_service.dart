import 'dart:collection';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
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

typedef RowsUpdateNotifierValue = Either<List<GridRowData>, FlowyError>;

class GridBlockService {
  String gridId;
  List<Field> fields;
  LinkedHashMap<String, GridBlock> blockMap = LinkedHashMap();
  late GridBlockListener _blockListener;
  PublishNotifier<RowsUpdateNotifierValue> rowsUpdateNotifier = PublishNotifier<RowsUpdateNotifierValue>();

  GridBlockService({required this.gridId, required this.fields, required List<GridBlockOrder> blockOrders}) {
    _loadGridBlocks(blockOrders: blockOrders);

    _blockListener = GridBlockListener(gridId: gridId);
    _blockListener.rowsUpdateNotifier.addPublishListener((result) {
      result.fold(
        (blockId) => _loadGridBlocks(blockOrders: [GridBlockOrder.create()..blockId = blockId.value]),
        (err) => Log.error(err),
      );
    });
    _blockListener.start();
  }

  List<GridRowData> buildRows() {
    List<GridRowData> rows = [];
    blockMap.forEach((_, GridBlock gridBlock) {
      rows.addAll(gridBlock.rowOrders.map(
        (rowOrder) => GridRowData(
          gridId: gridId,
          fields: fields,
          blockId: gridBlock.id,
          rowId: rowOrder.rowId,
          height: rowOrder.height.toDouble(),
        ),
      ));
    });
    return rows;
  }

  Future<void> stop() async {
    await _blockListener.stop();
  }

  void _loadGridBlocks({required List<GridBlockOrder> blockOrders}) {
    final payload = QueryGridBlocksPayload.create()
      ..gridId = gridId
      ..blockOrders.addAll(blockOrders);

    GridEventGetGridBlocks(payload).send().then((result) {
      result.fold(
        (repeatedBlocks) {
          for (final gridBlock in repeatedBlocks.items) {
            blockMap[gridBlock.id] = gridBlock;
          }
          rowsUpdateNotifier.value = left(buildRows());
        },
        (err) => rowsUpdateNotifier.value = right(err),
      );
    });
  }
}

class GridBlockListener {
  final String gridId;
  PublishNotifier<Either<GridBlockId, FlowyError>> rowsUpdateNotifier = PublishNotifier(comparable: null);
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
      case GridNotification.BlockDidUpdateRow:
        result.fold(
          (payload) => rowsUpdateNotifier.value = left(GridBlockId.fromBuffer(payload)),
          (error) => rowsUpdateNotifier.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    rowsUpdateNotifier.dispose();
  }
}
