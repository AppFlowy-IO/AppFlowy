import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/filter_changeset.pb.dart';
import 'package:dartz/dartz.dart';

typedef UpdateFilterNotifiedValue
    = Either<FilterChangesetNotificationPB, FlowyError>;

class FilterListener {
  final String viewId;

  PublishNotifier<UpdateFilterNotifiedValue>? _filterNotifier =
      PublishNotifier();
  GridNotificationListener? _listener;
  FilterListener({required this.viewId});

  void start({
    required void Function(UpdateFilterNotifiedValue) onFilterChanged,
  }) {
    _filterNotifier?.addPublishListener(onFilterChanged);
    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    GridNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridNotification.DidUpdateFilter:
        result.fold(
          (payload) => _filterNotifier?.value =
              left(FilterChangesetNotificationPB.fromBuffer(payload)),
          (error) => _filterNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _filterNotifier?.dispose();
    _filterNotifier = null;
  }
}
