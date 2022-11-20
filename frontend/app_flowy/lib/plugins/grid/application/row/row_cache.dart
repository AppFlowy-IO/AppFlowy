import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'row_cache.freezed.dart';

typedef RowUpdateCallback = void Function();

abstract class IGridRowFieldNotifier {
  UnmodifiableListView<GridFieldContext> get fields;
  void onRowFieldsChanged(VoidCallback callback);
  void onRowFieldChanged(void Function(FieldPB) callback);
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
    _hideRows(changeset.invisibleRows);
    _showRows(changeset.visibleRows);
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
        deletedIndex.add(DeletedIndex(index: index, row: rowInfo));
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
      final insertIndex = InsertedIndex(
        index: insertRow.index,
        rowId: insertRow.row.id,
      );
      insertIndexs.add(insertIndex);
      final rowInfo = buildGridRow(insertRow.row);
      _rowInfos.insert(insertRow.index, rowInfo);
      _rowInfoByRowId[rowInfo.rowPB.id] = rowInfo;
    }

    _rowChangeReasonNotifier.receive(RowsChangedReason.insert(insertIndexs));
  }

  void _updateRows(List<RowPB> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
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
    for (final rowId in invisibleRows) {
      _rowInfoByRowId[rowId]?.visible = false;
    }

    if (invisibleRows.isNotEmpty) {
      _rowChangeReasonNotifier
          .receive(const RowsChangedReason.filterDidChange());
    }
  }

  void _showRows(List<String> visibleRows) {
    for (final rowId in visibleRows) {
      _rowInfoByRowId[rowId]?.visible = true;
    }
    if (visibleRows.isNotEmpty) {
      _rowChangeReasonNotifier
          .receive(const RowsChangedReason.filterDidChange());
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
          fieldContext: field,
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
        final UpdatedIndexs updatedIndexs = UpdatedIndexs();
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
      filterDidChange: (_FilterDidChange value) => notifyListeners(),
    );
  }
}

@unfreezed
class RowInfo with _$RowInfo {
  factory RowInfo({
    required String gridId,
    required UnmodifiableListView<GridFieldContext> fields,
    required RowPB rowPB,
    required bool visible,
  }) = _RowInfo;
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
typedef UpdatedIndexs = LinkedHashMap<String, UpdatedIndex>;

@freezed
class RowsChangedReason with _$RowsChangedReason {
  const factory RowsChangedReason.insert(InsertedIndexs items) = _Insert;
  const factory RowsChangedReason.delete(DeletedIndexs items) = _Delete;
  const factory RowsChangedReason.update(UpdatedIndexs indexs) = _Update;
  const factory RowsChangedReason.fieldDidChange() = _FieldDidChange;
  const factory RowsChangedReason.filterDidChange() = _FilterDidChange;
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
  final RowInfo row;
  DeletedIndex({
    required this.index,
    required this.row,
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
