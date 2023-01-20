import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/filter_changeset.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/util.pb.dart';

typedef UpdateFilterNotifiedValue
    = Either<FilterChangesetNotificationPB, FlowyError>;

class FiltersListener {
  final String viewId;

  PublishNotifier<UpdateFilterNotifiedValue>? _filterNotifier =
      PublishNotifier();
  GridNotificationListener? _listener;
  FiltersListener({required this.viewId});

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
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateFilter:
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

class FilterListener {
  final String viewId;
  final String filterId;

  PublishNotifier<FilterPB>? _onDeleteNotifier = PublishNotifier();
  PublishNotifier<FilterPB>? _onUpdateNotifier = PublishNotifier();

  GridNotificationListener? _listener;
  FilterListener({required this.viewId, required this.filterId});

  void start({
    void Function()? onDeleted,
    void Function(FilterPB)? onUpdated,
  }) {
    _onDeleteNotifier?.addPublishListener((_) {
      onDeleted?.call();
    });

    _onUpdateNotifier?.addPublishListener((filter) {
      onUpdated?.call(filter);
    });

    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void handleChangeset(FilterChangesetNotificationPB changeset) {
    // check the delete filter
    final deletedIndex = changeset.deleteFilters.indexWhere(
      (element) => element.id == filterId,
    );
    if (deletedIndex != -1) {
      _onDeleteNotifier?.value = changeset.deleteFilters[deletedIndex];
    }

    // check the updated filter
    final updatedIndex = changeset.updateFilters.indexWhere(
      (element) => element.filter.id == filterId,
    );
    if (updatedIndex != -1) {
      _onUpdateNotifier?.value = changeset.updateFilters[updatedIndex].filter;
    }
  }

  void _handler(
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateFilter:
        result.fold(
          (payload) => handleChangeset(
              FilterChangesetNotificationPB.fromBuffer(payload)),
          (error) {},
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _onDeleteNotifier?.dispose();
    _onDeleteNotifier = null;

    _onUpdateNotifier?.dispose();
    _onUpdateNotifier = null;
  }
}
