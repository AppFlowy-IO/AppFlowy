import 'dart:collection';

import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';

import 'row_cache.dart';

class RowList {
  /// _rows containers the current block's rows
  /// Use List to reverse the order of the GridRow.
  List<RowInfo> _rowInfos = [];

  List<RowInfo> get rows => List.from(_rowInfos);

  /// Use Map for faster access the raw row data.
  final HashMap<String, RowInfo> _rowInfoByRowId = HashMap();

  RowInfo? get(String rowId) {
    return _rowInfoByRowId[rowId];
  }

  int? indexOfRow(String rowId) {
    final rowInfo = _rowInfoByRowId[rowId];
    if (rowInfo != null) {
      return _rowInfos.indexOf(rowInfo);
    }
    return null;
  }

  void add(RowInfo rowInfo) {
    final rowId = rowInfo.rowPB.id;
    if (contains(rowId)) {
      final index =
          _rowInfos.indexWhere((element) => element.rowPB.id == rowId);
      _rowInfos.removeAt(index);
      _rowInfos.insert(index, rowInfo);
    } else {
      _rowInfos.add(rowInfo);
    }
    _rowInfoByRowId[rowId] = rowInfo;
  }

  InsertedIndex? insert(int index, RowInfo rowInfo) {
    final rowId = rowInfo.rowPB.id;
    var insertedIndex = index;
    if (_rowInfos.length <= insertedIndex) {
      insertedIndex = _rowInfos.length;
    }

    final oldRowInfo = get(rowId);
    if (oldRowInfo != null) {
      _rowInfos.insert(insertedIndex, rowInfo);
      _rowInfos.remove(oldRowInfo);
      _rowInfoByRowId[rowId] = rowInfo;
      return null;
    } else {
      _rowInfos.insert(insertedIndex, rowInfo);
      _rowInfoByRowId[rowId] = rowInfo;
      return InsertedIndex(index: insertedIndex, rowId: rowId);
    }
  }

  DeletedIndex? remove(String rowId) {
    final rowInfo = _rowInfoByRowId[rowId];
    if (rowInfo != null) {
      final index = _rowInfos.indexOf(rowInfo);
      if (index != -1) {
        _rowInfoByRowId.remove(rowInfo.rowPB.id);
        _rowInfos.remove(rowInfo);
      }
      return DeletedIndex(index: index, rowInfo: rowInfo);
    } else {
      return null;
    }
  }

  InsertedIndexs insertRows(
    List<InsertedRowPB> insertedRows,
    RowInfo Function(RowPB) builder,
  ) {
    InsertedIndexs insertIndexs = [];
    for (final insertRow in insertedRows) {
      final isContains = contains(insertRow.row.id);

      var index = insertRow.index;
      if (_rowInfos.length < index) {
        index = _rowInfos.length;
      }
      insert(index, builder(insertRow.row));

      if (!isContains) {
        insertIndexs.add(InsertedIndex(
          index: index,
          rowId: insertRow.row.id,
        ));
      }
    }
    return insertIndexs;
  }

  DeletedIndexs removeRows(List<String> rowIds) {
    final List<RowInfo> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, String> deletedRowByRowId = {
      for (var rowId in rowIds) rowId: rowId
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
    return deletedIndex;
  }

  UpdatedIndexMap updateRows(
    List<RowPB> updatedRows,
    RowInfo Function(RowPB) builder,
  ) {
    final UpdatedIndexMap updatedIndexs = UpdatedIndexMap();
    for (final RowPB updatedRow in updatedRows) {
      final rowId = updatedRow.id;
      final index = _rowInfos.indexWhere(
        (rowInfo) => rowInfo.rowPB.id == rowId,
      );
      if (index != -1) {
        final rowInfo = builder(updatedRow);
        insert(index, rowInfo);
        updatedIndexs[rowId] = UpdatedIndex(index: index, rowId: rowId);
      }
    }
    return updatedIndexs;
  }

  List<DeletedIndex> markRowsAsInvisible(List<String> rowIds) {
    final List<DeletedIndex> deletedRows = [];

    for (final rowId in rowIds) {
      final rowInfo = _rowInfoByRowId[rowId];
      if (rowInfo != null) {
        final index = _rowInfos.indexOf(rowInfo);
        if (index != -1) {
          deletedRows.add(DeletedIndex(index: index, rowInfo: rowInfo));
        }
      }
    }
    return deletedRows;
  }

  bool contains(String rowId) {
    return _rowInfoByRowId[rowId] != null;
  }
}
