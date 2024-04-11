import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:flutter/material.dart';

import '../cell/cell_cache.dart';
import '../cell/cell_controller.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(List<CellContext>, ChangedReason);

class RowController {
  RowController({
    required this.rowMeta,
    required this.viewId,
    required RowCache rowCache,
    this.groupId,
  }) : _rowCache = rowCache;

  final RowMetaPB rowMeta;
  final String? groupId;
  final String viewId;
  final List<VoidCallback> _onRowChangedListeners = [];
  final RowCache _rowCache;

  CellMemCache get cellCache => _rowCache.cellCache;

  String get rowId => rowMeta.id;

  List<CellContext> loadData() => _rowCache.loadCells(rowMeta);

  void addListener({OnRowChanged? onRowChanged}) {
    final fn = _rowCache.addListener(
      rowId: rowMeta.id,
      onRowChanged: onRowChanged,
    );

    // Add the listener to the list so that we can remove it later.
    _onRowChangedListeners.add(fn);
  }

  void dispose() {
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }
}
