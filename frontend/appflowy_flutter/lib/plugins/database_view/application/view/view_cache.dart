import 'dart:async';
import 'dart:collection';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import '../defines.dart';
import '../field/field_controller.dart';
import '../row/row_cache.dart';
import 'view_listener.dart';

class DatabaseViewCallbacks {
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

  const DatabaseViewCallbacks({
    this.onNumOfRowsChanged,
    this.onRowsCreated,
    this.onRowsUpdated,
    this.onRowsDeleted,
  });
}

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class DatabaseViewCache {
  final String viewId;
  late RowCache _rowCache;
  final DatabaseViewListener _databaseViewListener;
  final List<DatabaseViewCallbacks> _callbacks = [];

  UnmodifiableListView<RowInfo> get rowInfos => _rowCache.rowInfos;
  RowCache get rowCache => _rowCache;

  RowInfo? getRow(RowId rowId) => _rowCache.getRow(rowId);

  DatabaseViewCache({
    required this.viewId,
    required FieldController fieldController,
  }) : _databaseViewListener = DatabaseViewListener(viewId: viewId) {
    final delegate = RowDelegatesImpl(fieldController);
    _rowCache = RowCache(
      viewId: viewId,
      fieldsDelegate: delegate,
      cacheDelegate: delegate,
    );

    _databaseViewListener.start(
      onRowsChanged: (result) {
        result.fold(
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
        );
      },
      onRowsVisibilityChanged: (result) {
        result.fold(
          (changeset) => _rowCache.applyRowsVisibility(changeset),
          (err) => Log.error(err),
        );
      },
      onReorderAllRows: (result) {
        result.fold(
          (rowIds) => _rowCache.reorderAllRows(rowIds),
          (err) => Log.error(err),
        );
      },
      onReorderSingleRow: (result) {
        result.fold(
          (reorderRow) => _rowCache.reorderSingleRow(reorderRow),
          (err) => Log.error(err),
        );
      },
    );

    _rowCache.onRowsChanged(
      (reason) {
        for (final callback in _callbacks) {
          callback.onNumOfRowsChanged?.call(
            rowInfos,
            _rowCache.rowByRowId,
            reason,
          );
        }
      },
    );
  }

  Future<void> dispose() async {
    await _databaseViewListener.stop();
    await _rowCache.dispose();
    _callbacks.clear();
  }

  void addListener(DatabaseViewCallbacks callbacks) {
    _callbacks.add(callbacks);
  }
}
