import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../cell/cell_cache.dart';
import '../cell/cell_controller.dart';

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

/// Read https://docs.appflowy.io/docs/documentation/software-contributions/architecture/frontend/frontend/grid for more information.

class RowCache {
  RowCache({
    required this.viewId,
    required RowFieldsDelegate fieldsDelegate,
    required RowLifeCycle rowLifeCycle,
  })  : _cellMemCache = CellMemCache(),
        _changedNotifier = RowChangesetNotifier(),
        _rowLifeCycle = rowLifeCycle,
        _fieldDelegate = fieldsDelegate {
    // Listen to field changes. If a field is deleted, we can safely remove the
    // cells corresponding to that field from our cache.
    fieldsDelegate.onFieldsChanged((fieldInfos) {
      for (final fieldInfo in fieldInfos) {
        _cellMemCache.removeCellWithFieldId(fieldInfo.id);
      }

      _changedNotifier?.receive(const ChangedReason.fieldDidChange());
    });
  }

  final String viewId;
  final RowList _rowList = RowList();
  final CellMemCache _cellMemCache;
  final RowLifeCycle _rowLifeCycle;
  final RowFieldsDelegate _fieldDelegate;
  RowChangesetNotifier? _changedNotifier;
  bool _isInitialRows = false;
  final List<RowsVisibilityChangePB> _pendingVisibilityChanges = [];

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
  ChangedReason get changeReason =>
      _changedNotifier?.reason ?? const InitialListState();

  RowInfo? getRow(RowId rowId) {
    return _rowList.get(rowId);
  }

  void setInitialRows(List<RowMetaPB> rows) {
    for (final row in rows) {
      final rowInfo = buildGridRow(row);
      _rowList.add(rowInfo);
    }
    _isInitialRows = true;
    _changedNotifier?.receive(const ChangedReason.setInitialRows());

    for (final changeset in _pendingVisibilityChanges) {
      applyRowsVisibility(changeset);
    }
    _pendingVisibilityChanges.clear();
  }

  void setRowMeta(RowMetaPB rowMeta) {
    final rowInfo = buildGridRow(rowMeta);
    _rowList.add(rowInfo);
    _changedNotifier?.receive(const ChangedReason.didFetchRow());
  }

  void dispose() {
    _rowLifeCycle.onRowDisposed();
    _changedNotifier?.dispose();
    _changedNotifier = null;
    _cellMemCache.dispose();
  }

  void applyRowsChanged(RowsChangePB changeset) {
    _deleteRows(changeset.deletedRows);
    _insertRows(changeset.insertedRows);
    _updateRows(changeset.updatedRows);
  }

  void applyRowsVisibility(RowsVisibilityChangePB changeset) {
    if (_isInitialRows) {
      _hideRows(changeset.invisibleRows);
      _showRows(changeset.visibleRows);
    } else {
      _pendingVisibilityChanges.add(changeset);
    }
  }

  void reorderAllRows(List<String> rowIds) {
    _rowList.reorderWithRowIds(rowIds);
    _changedNotifier?.receive(const ChangedReason.reorderRows());
  }

  void reorderSingleRow(ReorderSingleRowPB reorderRow) {
    final rowInfo = _rowList.get(reorderRow.rowId);
    if (rowInfo != null) {
      _rowList.moveRow(
        reorderRow.rowId,
        reorderRow.oldIndex,
        reorderRow.newIndex,
      );
      _changedNotifier?.receive(
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
        _changedNotifier?.receive(ChangedReason.delete(deletedRow));
      }
    }
  }

  void _insertRows(List<InsertedRowPB> insertRows) {
    for (final insertedRow in insertRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.rowMeta));
      if (insertedIndex != null) {
        _changedNotifier?.receive(ChangedReason.insert(insertedIndex));
      }
    }
  }

  void _updateRows(List<UpdatedRowPB> updatedRows) {
    if (updatedRows.isEmpty) return;
    final List<RowMetaPB> updatedList = [];
    for (final updatedRow in updatedRows) {
      for (final fieldId in updatedRow.fieldIds) {
        final key = CellContext(
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
      _changedNotifier?.receive(ChangedReason.update(updatedIndexs));
    }
  }

  void _hideRows(List<RowId> invisibleRows) {
    for (final rowId in invisibleRows) {
      final deletedRow = _rowList.remove(rowId);
      if (deletedRow != null) {
        _changedNotifier?.receive(ChangedReason.delete(deletedRow));
      }
    }
  }

  void _showRows(List<InsertedRowPB> visibleRows) {
    for (final insertedRow in visibleRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.rowMeta));
      if (insertedIndex != null) {
        _changedNotifier?.receive(ChangedReason.insert(insertedIndex));
      }
    }
  }

  void onRowsChanged(void Function(ChangedReason) onRowChanged) {
    _changedNotifier?.addListener(() {
      if (_changedNotifier != null) {
        onRowChanged(_changedNotifier!.reason);
      }
    });
  }

  RowUpdateCallback addListener({
    required RowId rowId,
    void Function(List<CellContext>, ChangedReason)? onRowChanged,
  }) {
    void listenerHandler() async {
      if (onRowChanged != null) {
        final rowInfo = _rowList.get(rowId);
        if (rowInfo != null) {
          final cellDataMap = _makeCells(rowInfo.rowMeta);
          if (_changedNotifier != null) {
            onRowChanged(cellDataMap, _changedNotifier!.reason);
          }
        }
      }
    }

    _changedNotifier?.addListener(listenerHandler);
    return listenerHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _changedNotifier?.removeListener(callback);
  }

  List<CellContext> loadCells(RowMetaPB rowMeta) {
    final rowInfo = _rowList.get(rowMeta.id);
    if (rowInfo == null) {
      _loadRow(rowMeta.id);
    }
    final cells = _makeCells(rowMeta);
    return cells;
  }

  Future<void> _loadRow(RowId rowId) async {
    final result = await RowBackendService.getRow(viewId: viewId, rowId: rowId);
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

          _changedNotifier?.receive(ChangedReason.update(updatedIndexs));
        }
      },
      (err) => Log.error(err),
    );
  }

  List<CellContext> _makeCells(RowMetaPB rowMeta) {
    return _fieldDelegate.fieldInfos
        .map(
          (fieldInfo) => CellContext(
            rowId: rowMeta.id,
            fieldId: fieldInfo.id,
          ),
        )
        .toList();
  }

  RowInfo buildGridRow(RowMetaPB rowMetaPB) {
    return RowInfo(
      fields: _fieldDelegate.fieldInfos,
      rowMeta: rowMetaPB,
    );
  }
}

class RowChangesetNotifier extends ChangeNotifier {
  RowChangesetNotifier();

  ChangedReason reason = const InitialListState();

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
      didFetchRow: (_) => notifyListeners(),
    );
  }
}

@unfreezed
class RowInfo with _$RowInfo {
  const RowInfo._();
  factory RowInfo({
    required UnmodifiableListView<FieldInfo> fields,
    required RowMetaPB rowMeta,
  }) = _RowInfo;

  String get rowId => rowMeta.id;
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
  const factory ChangedReason.didFetchRow() = _DidFetchRow;
  const factory ChangedReason.reorderRows() = _ReorderRows;
  const factory ChangedReason.reorderSingleRow(
    ReorderSingleRowPB reorderRow,
    RowInfo rowInfo,
  ) = _ReorderSingleRow;
  const factory ChangedReason.setInitialRows() = _SetInitialRows;
}

class InsertedIndex {
  InsertedIndex({
    required this.index,
    required this.rowId,
  });

  final int index;
  final RowId rowId;
}

class DeletedIndex {
  DeletedIndex({
    required this.index,
    required this.rowInfo,
  });

  final int index;
  final RowInfo rowInfo;
}

class UpdatedIndex {
  UpdatedIndex({
    required this.index,
    required this.rowId,
  });

  final int index;
  final RowId rowId;
}
