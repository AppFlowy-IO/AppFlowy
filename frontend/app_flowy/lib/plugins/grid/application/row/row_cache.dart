import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'row_cache.freezed.dart';

typedef RowUpdateCallback = void Function();

abstract class IGridRowFieldNotifier {
  UnmodifiableListView<FieldInfo> get fields;
  void onRowFieldsChanged(VoidCallback callback);
  void onRowFieldChanged(void Function(FieldInfo) callback);
  void onRowDispose();
}

/// Cache the rows in memory
/// Insert / delete / update row
///
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information.

class GridRowCache {
  final String gridId;
  final BlockPB block;

  /// _rows containers the current block's rows
  /// Use List to reverse the order of the GridRow.
  List<RowInfo> _rowInfos = [];

  /// Use Map for faster access the raw row data.
  final HashMap<String, RowInfo> _rowInfoByRowId;

  final GridCellCache _cellCache;
  final IGridRowFieldNotifier _fieldNotifier;
  final _RowChangesetNotifier _rowChangeReasonNotifier;

  UnmodifiableListView<RowInfo> get visibleRows {
    var visibleRows = [..._rowInfos];
    visibleRows.retainWhere((element) => element.visible);
    return UnmodifiableListView(visibleRows);
  }

  GridCellCache get cellCache => _cellCache;

  GridRowCache({
    required this.gridId,
    required this.block,
    required IGridRowFieldNotifier notifier,
  })  : _cellCache = GridCellCache(gridId: gridId),
        _rowInfoByRowId = HashMap(),
        _rowChangeReasonNotifier = _RowChangesetNotifier(),
        _fieldNotifier = notifier {
    //
    notifier.onRowFieldsChanged(() => _rowChangeReasonNotifier
        .receive(const RowsChangedReason.fieldDidChange()));
    notifier.onRowFieldChanged(
        (field) => _cellCache.removeCellWithFieldId(field.id));

    for (final row in block.rows) {
      final rowInfo = buildGridRow(row);
      _rowInfos.add(rowInfo);
      _rowInfoByRowId[rowInfo.rowPB.id] = rowInfo;
    }
  }

  Future<void> dispose() async {
    _fieldNotifier.onRowDispose();
    _rowChangeReasonNotifier.dispose();
    await _cellCache.dispose();
  }

  void applyChangesets(GridBlockChangesetPB changeset) {
    _deleteRows(changeset.deletedRows);
    _insertRows(changeset.insertedRows);
    _updateRows(changeset.updatedRows);
    _showRows(changeset.visibleRows);
    _hideRows(changeset.invisibleRows);
  }

  void _deleteRows(List<String> deletedRows) {
    if (deletedRows.isEmpty) {
      return;
    }

    final List<RowInfo> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, String> deletedRowByRowId = {
      for (var rowId in deletedRows) rowId: rowId
    };

    _rowInfos.asMap().forEach((index, RowInfo rowInfo) {
      if (deletedRowByRowId[rowInfo.rowPB.id] == null) {
        newRows.add(rowInfo);
      } else {
        _rowInfoByRowId.remove(rowInfo.rowPB.id);
        deletedIndex.add(DeletedIndex(index: index, rowInfo: rowInfo));
      }
    });
    _rowInfos = newRows;
    _rowChangeReasonNotifier.receive(RowsChangedReason.delete(deletedIndex));
  }

  void _insertRows(List<InsertedRowPB> insertRows) {
    if (insertRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    for (final InsertedRowPB insertRow in insertRows) {
      var index = insertRow.index;
      final rowInfo = buildGridRow(insertRow.row);
      if (_rowInfos.length > insertRow.index) {
        _rowInfos.insert(insertRow.index, rowInfo);
      } else {
        index = _rowInfos.length;
        _rowInfos.add(rowInfo);
      }
      insertIndexs.add(InsertedIndex(
        index: index,
        rowId: insertRow.row.id,
      ));
      _rowInfoByRowId[rowInfo.rowPB.id] = rowInfo;
    }

    _rowChangeReasonNotifier.receive(RowsChangedReason.insert(insertIndexs));
  }

  void _updateRows(List<RowPB> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexMap updatedIndexs = UpdatedIndexMap();
    for (final RowPB updatedRow in updatedRows) {
      final rowId = updatedRow.id;
      final index = _rowInfos.indexWhere(
        (rowInfo) => rowInfo.rowPB.id == rowId,
      );
      if (index != -1) {
        final rowInfo = buildGridRow(updatedRow);
        _rowInfoByRowId[rowId] = rowInfo;

        _rowInfos.removeAt(index);
        _rowInfos.insert(index, rowInfo);
        updatedIndexs[rowId] = UpdatedIndex(index: index, rowId: rowId);
      }
    }

    _rowChangeReasonNotifier.receive(RowsChangedReason.update(updatedIndexs));
  }

  void _hideRows(List<String> invisibleRows) {
    final List<DeletedIndex> deletedRows = [];

    for (final rowId in invisibleRows) {
      final rowInfo = _rowInfoByRowId[rowId];
      if (rowInfo != null) {
        rowInfo.visible = false;
        final index = _rowInfos.indexOf(rowInfo);
        if (index != -1) {
          deletedRows.add(DeletedIndex(index: index, rowInfo: rowInfo));

          _rowInfoByRowId.remove(rowInfo.rowPB.id);
          _rowInfos.remove(rowInfo);
        }
      }
    }

    if (deletedRows.isNotEmpty) {
      _rowChangeReasonNotifier.receive(RowsChangedReason.delete(deletedRows));
    }
  }

  void _showRows(List<InsertedRowPB> visibleRows) {
    final List<InsertedIndex> insertedRows = [];
    for (final indexedRow in visibleRows) {
      final rowId = indexedRow.row.id;
      var index = indexedRow.index;
      final newRowInfo = buildGridRow(indexedRow.row);
      _rowInfoByRowId[rowId] = newRowInfo;

      if (_rowInfos.length > index) {
        _rowInfos.insert(index, newRowInfo);
      } else {
        index = _rowInfos.length;
        _rowInfos.add(newRowInfo);
      }
      insertedRows.add(InsertedIndex(index: index, rowId: rowId));
    }
    if (insertedRows.isNotEmpty) {
      _rowChangeReasonNotifier.receive(RowsChangedReason.insert(insertedRows));
    }
  }

  void onRowsChanged(void Function(RowsChangedReason) onRowChanged) {
    _rowChangeReasonNotifier.addListener(() {
      onRowChanged(_rowChangeReasonNotifier.reason);
    });
  }

  RowUpdateCallback addListener({
    required String rowId,
    void Function(GridCellMap, RowsChangedReason)? onCellUpdated,
    bool Function()? listenWhen,
  }) {
    listenerHandler() async {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      notifyUpdate() {
        if (onCellUpdated != null) {
          final rowInfo = _rowInfoByRowId[rowId];
          if (rowInfo != null) {
            final GridCellMap cellDataMap =
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

  GridCellMap loadGridCells(String rowId) {
    final RowPB? data = _rowInfoByRowId[rowId]?.rowPB;
    if (data == null) {
      _loadRow(rowId);
    }
    return _makeGridCells(rowId, data);
  }

  Future<void> _loadRow(String rowId) async {
    final payload = RowIdPB.create()
      ..gridId = gridId
      ..blockId = block.id
      ..rowId = rowId;

    final result = await GridEventGetRow(payload).send();
    result.fold(
      (optionRow) => _refreshRow(optionRow),
      (err) => Log.error(err),
    );
  }

  GridCellMap _makeGridCells(String rowId, RowPB? row) {
    // ignore: prefer_collection_literals
    var cellDataMap = GridCellMap();
    for (final field in _fieldNotifier.fields) {
      if (field.visibility) {
        cellDataMap[field.id] = GridCellIdentifier(
          rowId: rowId,
          gridId: gridId,
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

    final index =
        _rowInfos.indexWhere((rowInfo) => rowInfo.rowPB.id == updatedRow.id);
    if (index != -1) {
      // update the corresponding row in _rows if they are not the same
      if (_rowInfos[index].rowPB != updatedRow) {
        final rowInfo = _rowInfos.removeAt(index).copyWith(rowPB: updatedRow);
        _rowInfos.insert(index, rowInfo);
        _rowInfoByRowId[rowInfo.rowPB.id] = rowInfo;

        // Calculate the update index
        final UpdatedIndexMap updatedIndexs = UpdatedIndexMap();
        updatedIndexs[rowInfo.rowPB.id] = UpdatedIndex(
          index: index,
          rowId: rowInfo.rowPB.id,
        );

        //
        _rowChangeReasonNotifier
            .receive(RowsChangedReason.update(updatedIndexs));
      }
    }
  }

  RowInfo buildGridRow(RowPB rowPB) {
    return RowInfo(
      gridId: gridId,
      fields: _fieldNotifier.fields,
      rowPB: rowPB,
      visible: true,
    );
  }
}

class _RowChangesetNotifier extends ChangeNotifier {
  RowsChangedReason reason = const InitialListState();

  _RowChangesetNotifier();

  void receive(RowsChangedReason newReason) {
    reason = newReason;
    reason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      fieldDidChange: (_) => notifyListeners(),
      initial: (_) {},
    );
  }
}

@unfreezed
class RowInfo with _$RowInfo {
  factory RowInfo({
    required String gridId,
    required UnmodifiableListView<FieldInfo> fields,
    required RowPB rowPB,
    required bool visible,
  }) = _RowInfo;
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
// key: id of the row
// value: UpdatedIndex
typedef UpdatedIndexMap = LinkedHashMap<String, UpdatedIndex>;

@freezed
class RowsChangedReason with _$RowsChangedReason {
  const factory RowsChangedReason.insert(InsertedIndexs items) = _Insert;
  const factory RowsChangedReason.delete(DeletedIndexs items) = _Delete;
  const factory RowsChangedReason.update(UpdatedIndexMap indexs) = _Update;
  const factory RowsChangedReason.fieldDidChange() = _FieldDidChange;
  const factory RowsChangedReason.initial() = InitialListState;
}

class InsertedIndex {
  final int index;
  final String rowId;
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
  final String rowId;
  UpdatedIndex({
    required this.index,
    required this.rowId,
  });
}
