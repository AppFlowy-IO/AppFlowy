import 'dart:collection';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../cell/cell_service.dart';
import 'row_list.dart';
import 'row_service.dart';
part 'row_cache.freezed.dart';

typedef RowUpdateCallback = void Function();

/// A delegate that provides the fields of the row.
abstract class RowFieldsDelegate {
  UnmodifiableListView<FieldInfo> get fieldInfos;
  void onFieldsChanged(void Function(List<FieldInfo>) callback);
}

abstract mixin class RowLifeCycle {
  void onRowDisposed();
}

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information.

class RowCache {
  final String viewId;
  final RowList _rowList = RowList();
  final CellMemCache _cellMemCache;
  final RowLifeCycle _rowLifeCycle;
  final RowFieldsDelegate _fieldDelegate;
  final RowChangesetNotifier _changedNotifier;

  /// Returns a unmodifiable list of RowInfo
  UnmodifiableListView<RowInfo> get rowInfos {
    final visibleRows = [..._rowList.rows];
    return UnmodifiableListView(visibleRows);
  }

  /// Returns a unmodifiable map of RowInfo
  UnmodifiableMapView<RowId, RowInfo> get rowByRowId {
    return UnmodifiableMapView(_rowList.rowInfoByRowId);
  }

  CellMemCache get cellCache => _cellMemCache;
  ChangedReason get changeReason => _changedNotifier.reason;

  RowCache({
    required this.viewId,
    required RowFieldsDelegate fieldsDelegate,
    required RowLifeCycle rowLifeCycle,
  })  : _cellMemCache = CellMemCache(viewId: viewId),
        _changedNotifier = RowChangesetNotifier(),
        _rowLifeCycle = rowLifeCycle,
        _fieldDelegate = fieldsDelegate {
    // Listen on the changed of the fields. If the fields changed, we need to
    // clear the cell cache with the given field id.
    fieldsDelegate.onFieldsChanged((fieldInfos) {
      for (final fieldInfo in fieldInfos) {
        _cellMemCache.removeCellWithFieldId(fieldInfo.id);
      }
      _changedNotifier.receive(const ChangedReason.fieldDidChange());
    });
  }

  RowInfo? getRow(RowId rowId) {
    return _rowList.get(rowId);
  }

  void setInitialRows(List<RowMetaPB> rows) {
    for (final row in rows) {
      final rowInfo = buildGridRow(row);
      _rowList.add(rowInfo);
    }
    _changedNotifier.receive(const ChangedReason.setInitialRows());
  }

  Future<void> dispose() async {
    _rowLifeCycle.onRowDisposed();
    _changedNotifier.dispose();
    await _cellMemCache.dispose();
  }

  void applyRowsChanged(RowsChangePB changeset) {
    _deleteRows(changeset.deletedRows);
    _insertRows(changeset.insertedRows);
    _updateRows(changeset.updatedRows);
  }

  void applyRowsVisibility(RowsVisibilityChangePB changeset) {
    _hideRows(changeset.invisibleRows);
    _showRows(changeset.visibleRows);
  }

  void reorderAllRows(List<String> rowIds) {
    _rowList.reorderWithRowIds(rowIds);
    _changedNotifier.receive(const ChangedReason.reorderRows());
  }

  void reorderSingleRow(ReorderSingleRowPB reorderRow) {
    final rowInfo = _rowList.get(reorderRow.rowId);
    if (rowInfo != null) {
      _rowList.moveRow(
        reorderRow.rowId,
        reorderRow.oldIndex,
        reorderRow.newIndex,
      );
      _changedNotifier.receive(
        ChangedReason.reorderSingleRow(
          reorderRow,
          rowInfo,
        ),
      );
    }
  }

  void _deleteRows(List<RowId> deletedRowIds) {
    for (final rowId in deletedRowIds) {
      final deletedRow = _rowList.remove(rowId);
      if (deletedRow != null) {
        _changedNotifier.receive(ChangedReason.delete(deletedRow));
      }
    }
  }

  void _insertRows(List<InsertedRowPB> insertRows) {
    for (final insertedRow in insertRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.rowMeta));
      if (insertedIndex != null) {
        _changedNotifier.receive(ChangedReason.insert(insertedIndex));
      }
    }
  }

  void _updateRows(List<UpdatedRowPB> updatedRows) {
    if (updatedRows.isEmpty) return;
    final List<RowMetaPB> updatedList = [];
    for (final updatedRow in updatedRows) {
      for (final fieldId in updatedRow.fieldIds) {
        final key = CellCacheKey(
          fieldId: fieldId,
          rowId: updatedRow.rowId,
        );
        _cellMemCache.remove(key);
      }
      if (updatedRow.hasRowMeta()) {
        updatedList.add(updatedRow.rowMeta);
      }
    }

    final updatedIndexs =
        _rowList.updateRows(updatedList, (rowId) => buildGridRow(rowId));

    if (updatedIndexs.isNotEmpty) {
      _changedNotifier.receive(ChangedReason.update(updatedIndexs));
    }
  }

  void _hideRows(List<RowId> invisibleRows) {
    for (final rowId in invisibleRows) {
      final deletedRow = _rowList.remove(rowId);
      if (deletedRow != null) {
        _changedNotifier.receive(ChangedReason.delete(deletedRow));
      }
    }
  }

  void _showRows(List<InsertedRowPB> visibleRows) {
    for (final insertedRow in visibleRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.rowMeta));
      if (insertedIndex != null) {
        _changedNotifier.receive(ChangedReason.insert(insertedIndex));
      }
    }
  }

  void onRowsChanged(void Function(ChangedReason) onRowChanged) {
    _changedNotifier.addListener(() {
      onRowChanged(_changedNotifier.reason);
    });
  }

  RowUpdateCallback addListener({
    required RowId rowId,
    void Function(CellContextByFieldId, ChangedReason)? onRowChanged,
  }) {
    listenerHandler() async {
      if (onRowChanged != null) {
        final rowInfo = _rowList.get(rowId);
        if (rowInfo != null) {
          final cellDataMap = _makeCells(rowInfo.rowMeta);
          onRowChanged(cellDataMap, _changedNotifier.reason);
        }
      }
    }

    _changedNotifier.addListener(listenerHandler);
    return listenerHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _changedNotifier.removeListener(callback);
  }

  CellContextByFieldId loadCells(RowMetaPB rowMeta) {
    final rowInfo = _rowList.get(rowMeta.id);
    if (rowInfo == null) {
      _loadRow(rowMeta.id);
    }
    return _makeCells(rowMeta);
  }

  Future<void> _loadRow(RowId rowId) async {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    final result = await DatabaseEventGetRowMeta(payload).send();
    result.fold(
      (rowMetaPB) {
        final rowInfo = _rowList.get(rowMetaPB.id);
        final rowIndex = _rowList.indexOfRow(rowMetaPB.id);
        if (rowInfo != null && rowIndex != null) {
          final updatedRowInfo = rowInfo.copyWith(rowMeta: rowMetaPB);
          _rowList.remove(rowMetaPB.id);
          _rowList.insert(rowIndex, updatedRowInfo);

          final UpdatedIndexMap updatedIndexs = UpdatedIndexMap();
          updatedIndexs[rowMetaPB.id] = UpdatedIndex(
            index: rowIndex,
            rowId: rowMetaPB.id,
          );

          _changedNotifier.receive(ChangedReason.update(updatedIndexs));
        }
      },
      (err) => Log.error(err),
    );
  }

  CellContextByFieldId _makeCells(RowMetaPB rowMeta) {
    // ignore: prefer_collection_literals
    final cellContextMap = CellContextByFieldId();
    for (final fieldInfo in _fieldDelegate.fieldInfos) {
      cellContextMap[fieldInfo.id] = DatabaseCellContext(
        rowMeta: rowMeta,
        viewId: viewId,
        fieldInfo: fieldInfo,
      );
    }
    return cellContextMap;
  }

  RowInfo buildGridRow(RowMetaPB rowMetaPB) {
    return RowInfo(
      viewId: viewId,
      fields: _fieldDelegate.fieldInfos,
      rowId: rowMetaPB.id,
      rowMeta: rowMetaPB,
    );
  }
}

class RowChangesetNotifier extends ChangeNotifier {
  ChangedReason reason = const InitialListState();

  RowChangesetNotifier();

  void receive(ChangedReason newReason) {
    reason = newReason;
    reason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      fieldDidChange: (_) => notifyListeners(),
      initial: (_) {},
      reorderRows: (_) => notifyListeners(),
      reorderSingleRow: (_) => notifyListeners(),
      setInitialRows: (_) => notifyListeners(),
    );
  }
}

@unfreezed
class RowInfo with _$RowInfo {
  factory RowInfo({
    required String rowId,
    required String viewId,
    required UnmodifiableListView<FieldInfo> fields,
    required RowMetaPB rowMeta,
  }) = _RowInfo;
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
// key: id of the row
// value: UpdatedIndex
typedef UpdatedIndexMap = LinkedHashMap<RowId, UpdatedIndex>;

@freezed
class ChangedReason with _$ChangedReason {
  const factory ChangedReason.insert(InsertedIndex item) = _Insert;
  const factory ChangedReason.delete(DeletedIndex item) = _Delete;
  const factory ChangedReason.update(UpdatedIndexMap indexs) = _Update;
  const factory ChangedReason.fieldDidChange() = _FieldDidChange;
  const factory ChangedReason.initial() = InitialListState;
  const factory ChangedReason.reorderRows() = _ReorderRows;
  const factory ChangedReason.reorderSingleRow(
    ReorderSingleRowPB reorderRow,
    RowInfo rowInfo,
  ) = _ReorderSingleRow;
  const factory ChangedReason.setInitialRows() = _SetInitialRows;
}

class InsertedIndex {
  final int index;
  final RowId rowId;
  InsertedIndex({
    required this.index,
    required this.rowId,
  });
}

class DeletedIndex {
  final int index;
  final RowInfo rowInfo;
  DeletedIndex({
    required this.index,
    required this.rowInfo,
  });
}

class UpdatedIndex {
  final int index;
  final RowId rowId;
  UpdatedIndex({
    required this.index,
    required this.rowId,
  });
}
