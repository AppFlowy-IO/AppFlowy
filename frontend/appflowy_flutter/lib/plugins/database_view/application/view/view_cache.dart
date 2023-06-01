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
  DatabaseViewCallbacks? _callbacks;

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
              _callbacks?.onRowsDeleted?.call(changeset.deletedRows);
            }

            if (changeset.updatedRows.isNotEmpty) {
              _callbacks?.onRowsUpdated
                  ?.call(changeset.updatedRows.map((e) => e.row.id).toList());
            }

            if (changeset.insertedRows.isNotEmpty) {
              _callbacks?.onRowsCreated?.call(
                changeset.insertedRows
                    .map((insertedRow) => insertedRow.row.id)
                    .toList(),
              );
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
      (reason) => _callbacks?.onNumOfRowsChanged?.call(
        rowInfos,
        _rowCache.rowByRowId,
        reason,
      ),
    );
  }

  Future<void> dispose() async {
    await _databaseViewListener.stop();
    await _rowCache.dispose();
    _callbacks = null;
  }

  void setListener(DatabaseViewCallbacks callbacks) {
    _callbacks = callbacks;
  }
}
