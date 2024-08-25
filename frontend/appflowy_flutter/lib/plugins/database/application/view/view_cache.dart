import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import '../defines.dart';
import '../field/field_controller.dart';
import '../row/row_cache.dart';

import 'view_listener.dart';

class DatabaseViewCallbacks {
  const DatabaseViewCallbacks({
    this.onNumOfRowsChanged,
    this.onRowsCreated,
    this.onRowsUpdated,
    this.onRowsDeleted,
  });

  /// Will get called when number of rows were changed that includes
  /// update/delete/insert rows. The [onNumOfRowsChanged] will return all
  /// the rows of the current database
  final OnNumOfRowsChanged? onNumOfRowsChanged;

  // Will get called when creating new rows
  final OnRowsCreated? onRowsCreated;

  /// Will get called when rows were updated
  final OnRowsUpdated? onRowsUpdated;

  /// Will get called when number of rows were deleted
  final OnRowsDeleted? onRowsDeleted;
}

/// Read https://docs.appflowy.io/docs/documentation/software-contributions/architecture/frontend/frontend/grid for more information
class DatabaseViewCache {
  DatabaseViewCache({
    required this.viewId,
    required FieldController fieldController,
  }) : _databaseViewListener = DatabaseViewListener(viewId: viewId) {
    final depsImpl = RowCacheDependenciesImpl(fieldController);
    _rowCache = RowCache(
      viewId: viewId,
      fieldsDelegate: depsImpl,
      rowLifeCycle: depsImpl,
    );

    _databaseViewListener.start(
      onRowsChanged: (result) => result.fold(
        (changeset) {
          // Update the cache
          _rowCache.applyRowsChanged(changeset);

          if (changeset.deletedRows.isNotEmpty) {
            for (final callback in _callbacks) {
              callback.onRowsDeleted?.call(changeset.deletedRows);
            }
          }

          if (changeset.updatedRows.isNotEmpty) {
            for (final callback in _callbacks) {
              callback.onRowsUpdated?.call(
                changeset.updatedRows.map((e) => e.rowId).toList(),
                _rowCache.changeReason,
              );
            }
          }

          if (changeset.insertedRows.isNotEmpty) {
            for (final callback in _callbacks) {
              callback.onRowsCreated?.call(
                changeset.insertedRows
                    .map((insertedRow) => insertedRow.rowMeta.id)
                    .toList(),
              );
            }
          }
        },
        (err) => Log.error(err),
      ),
      onRowsVisibilityChanged: (result) => result.fold(
        (changeset) => _rowCache.applyRowsVisibility(changeset),
        (err) => Log.error(err),
      ),
      onReorderAllRows: (result) => result.fold(
        (rowIds) => _rowCache.reorderAllRows(rowIds),
        (err) => Log.error(err),
      ),
      onReorderSingleRow: (result) => result.fold(
        (reorderRow) => _rowCache.reorderSingleRow(reorderRow),
        (err) => Log.error(err),
      ),
    );

    _rowCache.onRowsChanged(
      (reason) {
        for (final callback in _callbacks) {
          callback.onNumOfRowsChanged
              ?.call(rowInfos, _rowCache.rowByRowId, reason);
        }
      },
    );
  }

  final String viewId;
  late RowCache _rowCache;
  final DatabaseViewListener _databaseViewListener;
  final List<DatabaseViewCallbacks> _callbacks = [];

  UnmodifiableListView<RowInfo> get rowInfos => _rowCache.rowInfos;
  RowCache get rowCache => _rowCache;

  RowInfo? getRow(RowId rowId) => _rowCache.getRow(rowId);

  Future<void> dispose() async {
    await _databaseViewListener.stop();
    _rowCache.dispose();
    _callbacks.clear();
  }

  void addListener(DatabaseViewCallbacks callbacks) {
    _callbacks.add(callbacks);
  }
}
