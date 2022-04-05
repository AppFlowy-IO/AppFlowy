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

typedef GridBlockMap = LinkedHashMap<String, GridBlock>;
typedef BlocksUpdateNotifierValue = Either<GridBlockMap, FlowyError>;

class GridBlockService {
  String gridId;
  GridBlockMap blockMap = GridBlockMap();
  late GridBlockListener _blockListener;
  PublishNotifier<BlocksUpdateNotifierValue>? blocksUpdateNotifier = PublishNotifier();

  GridBlockService({required this.gridId, required List<GridBlockOrder> blockOrders}) {
    _loadGridBlocks(blockOrders);

    _blockListener = GridBlockListener(gridId: gridId);
    _blockListener.blockUpdateNotifier.addPublishListener((result) {
      result.fold(
        (blockOrder) => _loadGridBlocks(blockOrder),
        (err) => Log.error(err),
      );
    });
    _blockListener.start();
  }

  Future<void> stop() async {
    await _blockListener.stop();
    blocksUpdateNotifier?.dispose();
    blocksUpdateNotifier = null;
  }

  void _loadGridBlocks(List<GridBlockOrder> blockOrders) {
    final payload = QueryGridBlocksPayload.create()
      ..gridId = gridId
      ..blockOrders.addAll(blockOrders);

    GridEventGetGridBlocks(payload).send().then((result) {
      result.fold(
        (repeatedBlocks) {
          for (final gridBlock in repeatedBlocks.items) {
            blockMap[gridBlock.id] = gridBlock;
          }
          blocksUpdateNotifier?.value = left(blockMap);
        },
        (err) => blocksUpdateNotifier?.value = right(err),
      );
    });
  }
}

class GridBlockListener {
  final String gridId;
  PublishNotifier<Either<List<GridBlockOrder>, FlowyError>> blockUpdateNotifier = PublishNotifier(comparable: null);
  StreamSubscription<SubscribeObject>? _subscription;
  GridNotificationParser? _parser;

  GridBlockListener({required this.gridId});

  void start() {
    _parser = GridNotificationParser(
      id: gridId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription = RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleObservableType(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateBlock:
        result.fold(
          (payload) => blockUpdateNotifier.value = left([GridBlockOrder.fromBuffer(payload)]),
          (error) => blockUpdateNotifier.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    blockUpdateNotifier.dispose();
  }
}
