import 'dart:typed_data';

import 'package:appflowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/filter_changeset.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database/util.pb.dart';

typedef UpdateFilterNotifiedValue
    = Either<FilterChangesetNotificationPB, FlowyError>;

class FiltersListener {
  final String viewId;

  PublishNotifier<UpdateFilterNotifiedValue>? _filterNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  FiltersListener({required this.viewId});

  void start({
    required final void Function(UpdateFilterNotifiedValue) onFilterChanged,
  }) {
    _filterNotifier?.addPublishListener(onFilterChanged);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    final DatabaseNotification ty,
    final Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateFilter:
        result.fold(
          (final payload) => _filterNotifier?.value =
              left(FilterChangesetNotificationPB.fromBuffer(payload)),
          (final error) => _filterNotifier?.value = right(error),
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

  DatabaseNotificationListener? _listener;
  FilterListener({required this.viewId, required this.filterId});

  void start({
    final void Function()? onDeleted,
    final void Function(FilterPB)? onUpdated,
  }) {
    _onDeleteNotifier?.addPublishListener((final _) {
      onDeleted?.call();
    });

    _onUpdateNotifier?.addPublishListener((final filter) {
      onUpdated?.call(filter);
    });

    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void handleChangeset(final FilterChangesetNotificationPB changeset) {
    // check the delete filter
    final deletedIndex = changeset.deleteFilters.indexWhere(
      (final element) => element.id == filterId,
    );
    if (deletedIndex != -1) {
      _onDeleteNotifier?.value = changeset.deleteFilters[deletedIndex];
    }

    // check the updated filter
    final updatedIndex = changeset.updateFilters.indexWhere(
      (final element) => element.filter.id == filterId,
    );
    if (updatedIndex != -1) {
      _onUpdateNotifier?.value = changeset.updateFilters[updatedIndex].filter;
    }
  }

  void _handler(
    final DatabaseNotification ty,
    final Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateFilter:
        result.fold(
          (final payload) => handleChangeset(
            FilterChangesetNotificationPB.fromBuffer(payload),
          ),
          (final error) {},
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
