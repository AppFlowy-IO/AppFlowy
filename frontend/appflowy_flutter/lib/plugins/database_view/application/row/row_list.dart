import 'dart:collection';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'row_cache.dart';
import 'row_service.dart';

class RowList {
  /// Use List to reverse the order of the row.
  List<RowInfo> _rowInfos = [];

  List<RowInfo> get rows => List.from(_rowInfos);

  /// Use Map for faster access the raw row data.
  final HashMap<RowId, RowInfo> rowInfoByRowId = HashMap();

  RowInfo? get(RowId rowId) {
    return rowInfoByRowId[rowId];
  }

  int? indexOfRow(RowId rowId) {
    final rowInfo = rowInfoByRowId[rowId];
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
    rowInfoByRowId[rowId] = rowInfo;
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
      rowInfoByRowId[rowId] = rowInfo;
      return null;
    } else {
      _rowInfos.insert(insertedIndex, rowInfo);
      rowInfoByRowId[rowId] = rowInfo;
      return InsertedIndex(index: insertedIndex, rowId: rowId);
    }
  }

  DeletedIndex? remove(RowId rowId) {
    final rowInfo = rowInfoByRowId[rowId];
    if (rowInfo != null) {
      final index = _rowInfos.indexOf(rowInfo);
      if (index != -1) {
        rowInfoByRowId.remove(rowInfo.rowPB.id);
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
    final InsertedIndexs insertIndexs = [];
    for (final insertRow in insertedRows) {
      final isContains = contains(insertRow.row.id);

      var index = insertRow.index;
      if (_rowInfos.length < index) {
        index = _rowInfos.length;
      }
      insert(index, builder(insertRow.row));

      if (!isContains) {
        insertIndexs.add(
          InsertedIndex(
            index: index,
            rowId: insertRow.row.id,
          ),
        );
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
        rowInfoByRowId.remove(rowInfo.rowPB.id);
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

  void reorderWithRowIds(List<String> rowIds) {
    _rowInfos.clear();

    for (final rowId in rowIds) {
      final rowInfo = rowInfoByRowId[rowId];
      if (rowInfo != null) {
        _rowInfos.add(rowInfo);
      }
    }
  }

  void moveRow(RowId rowId, int oldIndex, int newIndex) {
    final index = _rowInfos.indexWhere(
      (rowInfo) => rowInfo.rowPB.id == rowId,
    );
    if (index != -1) {
      final rowInfo = remove(rowId)!.rowInfo;
      insert(newIndex, rowInfo);
    }
  }

  bool contains(RowId rowId) {
    return rowInfoByRowId[rowId] != null;
  }
}
