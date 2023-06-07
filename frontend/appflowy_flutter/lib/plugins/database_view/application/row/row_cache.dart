import 'dart:collection';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../cell/cell_service.dart';
import '../field/field_controller.dart';
import 'row_list.dart';
import 'row_service.dart';
part 'row_cache.freezed.dart';

typedef RowUpdateCallback = void Function();

abstract class RowFieldsDelegate {
  void onFieldsChanged(void Function(List<FieldInfo>) callback);
}

abstract mixin class RowCacheDelegate {
  UnmodifiableListView<FieldInfo> get fields;
  void onRowDispose();
}

/// Cache the rows in memory
/// Insert / delete / update row
///
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information.

class RowCache {
  final String viewId;

  /// _rows contains the current block's rows
  /// Use List to reverse the order of the GridRow.
  final RowList _rowList = RowList();

  final CellCache _cellCache;
  final RowCacheDelegate _delegate;
  final RowChangesetNotifier _rowChangeReasonNotifier;

  UnmodifiableListView<RowInfo> get rowInfos {
    final visibleRows = [..._rowList.rows];
    return UnmodifiableListView(visibleRows);
  }

  UnmodifiableMapView<RowId, RowInfo> get rowByRowId {
    return UnmodifiableMapView(_rowList.rowInfoByRowId);
  }

  CellCache get cellCache => _cellCache;

  RowCache({
    required this.viewId,
    required RowFieldsDelegate fieldsDelegate,
    required RowCacheDelegate cacheDelegate,
  })  : _cellCache = CellCache(viewId: viewId),
        _rowChangeReasonNotifier = RowChangesetNotifier(),
        _delegate = cacheDelegate {
    //
    fieldsDelegate.onFieldsChanged((fieldInfos) {
      for (final fieldInfo in fieldInfos) {
        _cellCache.removeCellWithFieldId(fieldInfo.id);
      }
      _rowChangeReasonNotifier
          .receive(const RowsChangedReason.fieldDidChange());
    });
  }

  RowInfo? getRow(RowId rowId) {
    return _rowList.get(rowId);
  }

  void setInitialRows(List<RowPB> rows) {
    for (final row in rows) {
      final rowInfo = buildGridRow(row);
      _rowList.add(rowInfo);
    }
  }

  Future<void> dispose() async {
    _delegate.onRowDispose();
    _rowChangeReasonNotifier.dispose();
    await _cellCache.dispose();
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
    _rowChangeReasonNotifier.receive(const RowsChangedReason.reorderRows());
  }

  void reorderSingleRow(ReorderSingleRowPB reorderRow) {
    final rowInfo = _rowList.get(reorderRow.rowId);
    if (rowInfo != null) {
      _rowList.moveRow(
        reorderRow.rowId,
        reorderRow.oldIndex,
        reorderRow.newIndex,
      );
      _rowChangeReasonNotifier.receive(
        RowsChangedReason.reorderSingleRow(
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
        _rowChangeReasonNotifier.receive(RowsChangedReason.delete(deletedRow));
      }
    }
  }

  void _insertRows(List<InsertedRowPB> insertRows) {
    for (final insertedRow in insertRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.row));
      if (insertedIndex != null) {
        _rowChangeReasonNotifier
            .receive(RowsChangedReason.insert(insertedIndex));
      }
    }
  }

  void _updateRows(List<UpdatedRowPB> updatedRows) {
    if (updatedRows.isEmpty) return;
    final List<RowPB> rowPBs = [];
    for (final updatedRow in updatedRows) {
      for (final fieldId in updatedRow.fieldIds) {
        final key = CellCacheKey(
          fieldId: fieldId,
          rowId: updatedRow.row.id,
        );
        _cellCache.remove(key);
      }
      rowPBs.add(updatedRow.row);
    }

    final updatedIndexs =
        _rowList.updateRows(rowPBs, (rowPB) => buildGridRow(rowPB));
    if (updatedIndexs.isNotEmpty) {
      _rowChangeReasonNotifier.receive(RowsChangedReason.update(updatedIndexs));
    }
  }

  void _hideRows(List<RowId> invisibleRows) {
    for (final rowId in invisibleRows) {
      final deletedRow = _rowList.remove(rowId);
      if (deletedRow != null) {
        _rowChangeReasonNotifier.receive(RowsChangedReason.delete(deletedRow));
      }
    }
  }

  void _showRows(List<InsertedRowPB> visibleRows) {
    for (final insertedRow in visibleRows) {
      final insertedIndex =
          _rowList.insert(insertedRow.index, buildGridRow(insertedRow.row));
      if (insertedIndex != null) {
        _rowChangeReasonNotifier
            .receive(RowsChangedReason.insert(insertedIndex));
      }
    }
  }

  void onRowsChanged(void Function(RowsChangedReason) onRowChanged) {
    _rowChangeReasonNotifier.addListener(() {
      onRowChanged(_rowChangeReasonNotifier.reason);
    });
  }

  RowUpdateCallback addListener({
    required RowId rowId,
    void Function(CellContextByFieldId, RowsChangedReason)? onCellUpdated,
    bool Function()? listenWhen,
  }) {
    listenerHandler() async {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      notifyUpdate() {
        if (onCellUpdated != null) {
          final rowInfo = _rowList.get(rowId);
          if (rowInfo != null) {
            final CellContextByFieldId cellDataMap =
                _makeGridCells(rowId, rowInfo.rowPB);
            onCellUpdated(cellDataMap, _rowChangeReasonNotifier.reason);
          }
        }
      }

      _rowChangeReasonNotifier.reason.whenOrNull(
        update: (indexs) {
          if (indexs[rowId] != null) notifyUpdate();
        },
        fieldDidChange: () => notifyUpdate(),
      );
    }

    _rowChangeReasonNotifier.addListener(listenerHandler);
    return listenerHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _rowChangeReasonNotifier.removeListener(callback);
  }

  CellContextByFieldId loadGridCells(RowId rowId) {
    final RowPB? data = _rowList.get(rowId)?.rowPB;
    if (data == null) {
      _loadRow(rowId);
    }
    return _makeGridCells(rowId, data);
  }

  Future<void> _loadRow(RowId rowId) async {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    final result = await DatabaseEventGetRow(payload).send();
    result.fold(
      (optionRow) => _refreshRow(optionRow),
      (err) => Log.error(err),
    );
  }

  CellContextByFieldId _makeGridCells(RowId rowId, RowPB? row) {
    // ignore: prefer_collection_literals
    final cellDataMap = CellContextByFieldId();
    for (final field in _delegate.fields) {
      if (field.visibility) {
        cellDataMap[field.id] = DatabaseCellContext(
          rowId: rowId,
          viewId: viewId,
          fieldInfo: field,
        );
      }
    }
    return cellDataMap;
  }

  void _refreshRow(OptionalRowPB optionRow) {
    if (!optionRow.hasRow()) {
      return;
    }
    final updatedRow = optionRow.row;
    updatedRow.freeze();

    final rowInfo = _rowList.get(updatedRow.id);
    final rowIndex = _rowList.indexOfRow(updatedRow.id);
    if (rowInfo != null && rowIndex != null) {
      final updatedRowInfo = rowInfo.copyWith(rowPB: updatedRow);
      _rowList.remove(updatedRow.id);
      _rowList.insert(rowIndex, updatedRowInfo);

      final UpdatedIndexMap updatedIndexs = UpdatedIndexMap();
      updatedIndexs[rowInfo.rowPB.id] = UpdatedIndex(
        index: rowIndex,
        rowId: updatedRowInfo.rowPB.id,
      );

      _rowChangeReasonNotifier.receive(RowsChangedReason.update(updatedIndexs));
    }
  }

  RowInfo buildGridRow(RowPB rowPB) {
    return RowInfo(
      viewId: viewId,
      fields: _delegate.fields,
      rowPB: rowPB,
    );
  }
}

class RowChangesetNotifier extends ChangeNotifier {
  RowsChangedReason reason = const InitialListState();

  RowChangesetNotifier();

  void receive(RowsChangedReason newReason) {
    reason = newReason;
    reason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      fieldDidChange: (_) => notifyListeners(),
      initial: (_) {},
      reorderRows: (_) => notifyListeners(),
      reorderSingleRow: (_) => notifyListeners(),
    );
  }
}

@unfreezed
class RowInfo with _$RowInfo {
  factory RowInfo({
    required String viewId,
    required UnmodifiableListView<FieldInfo> fields,
    required RowPB rowPB,
  }) = _RowInfo;
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
// key: id of the row
// value: UpdatedIndex
typedef UpdatedIndexMap = LinkedHashMap<RowId, UpdatedIndex>;

@freezed
class RowsChangedReason with _$RowsChangedReason {
  const factory RowsChangedReason.insert(InsertedIndex item) = _Insert;
  const factory RowsChangedReason.delete(DeletedIndex item) = _Delete;
  const factory RowsChangedReason.update(UpdatedIndexMap indexs) = _Update;
  const factory RowsChangedReason.fieldDidChange() = _FieldDidChange;
  const factory RowsChangedReason.initial() = InitialListState;
  const factory RowsChangedReason.reorderRows() = _ReorderRows;
  const factory RowsChangedReason.reorderSingleRow(
    ReorderSingleRowPB reorderRow,
    RowInfo rowInfo,
  ) = _ReorderSingleRow;
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
