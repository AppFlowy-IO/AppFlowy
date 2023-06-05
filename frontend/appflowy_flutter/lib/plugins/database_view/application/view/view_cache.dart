import 'dart:async';
import 'dart:collection';
import 'package:appflowy_backend/log.dart';
import '../defines.dart';
import '../field/field_controller.dart';
import '../row/row_cache.dart';
import 'view_listener.dart';

class DatabaseViewCallbacks {
  /// Will get called when number of rows were changed that includes
  /// update/delete/insert rows. The [onRowsChanged] will return all
  /// the rows of the current database
  final OnRowsChanged? onRowsChanged;

  // Will get called when creating new rows
  final OnRowsCreated? onRowsCreated;

  /// Will get called when number of rows were updated
  final OnRowsUpdated? onRowsUpdated;

  /// Will get called when number of rows were deleted
  final OnRowsDeleted? onRowsDeleted;

  const DatabaseViewCallbacks({
    this.onRowsChanged,
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

  RowInfo? getRow(final String rowId) => _rowCache.getRow(rowId);

  DatabaseViewCache({
    required this.viewId,
    required final FieldController fieldController,
  }) : _databaseViewListener = DatabaseViewListener(viewId: viewId) {
    final delegate = RowDelegatesImpl(fieldController);
    _rowCache = RowCache(
      viewId: viewId,
      fieldsDelegate: delegate,
      cacheDelegate: delegate,
    );

    _databaseViewListener.start(
      onRowsChanged: (final result) {
        result.fold(
          (final changeset) {
            // Update the cache
            _rowCache.applyRowsChanged(changeset);

            if (changeset.deletedRows.isNotEmpty) {
              _callbacks?.onRowsDeleted?.call(changeset.deletedRows);
            }

            if (changeset.updatedRows.isNotEmpty) {
              _callbacks?.onRowsUpdated
                  ?.call(changeset.updatedRows.map((final e) => e.row.id).toList());
            }

            if (changeset.insertedRows.isNotEmpty) {
              _callbacks?.onRowsCreated?.call(
                changeset.insertedRows
                    .map((final insertedRow) => insertedRow.row.id)
                    .toList(),
              );
            }
          },
          (final err) => Log.error(err),
        );
      },
      onRowsVisibilityChanged: (final result) {
        result.fold(
          (final changeset) => _rowCache.applyRowsVisibility(changeset),
          (final err) => Log.error(err),
        );
      },
      onReorderAllRows: (final result) {
        result.fold(
          (final rowIds) => _rowCache.reorderAllRows(rowIds),
          (final err) => Log.error(err),
        );
      },
      onReorderSingleRow: (final result) {
        result.fold(
          (final reorderRow) => _rowCache.reorderSingleRow(reorderRow),
          (final err) => Log.error(err),
        );
      },
    );

    _rowCache.onRowsChanged(
      (final reason) => _callbacks?.onRowsChanged?.call(
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

  void setListener(final DatabaseViewCallbacks callbacks) {
    _callbacks = callbacks;
  }
}
