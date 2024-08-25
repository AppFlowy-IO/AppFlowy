import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/row_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:flutter/material.dart';

import '../cell/cell_cache.dart';
import '../cell/cell_controller.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(List<CellContext>, ChangedReason);

class RowController {
  RowController({
    required RowMetaPB rowMeta,
    required this.viewId,
    required RowCache rowCache,
    this.groupId,
  })  : _rowMeta = rowMeta,
        _rowCache = rowCache,
        _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowListener = RowListener(rowMeta.id);

  RowMetaPB _rowMeta;
  final String? groupId;
  VoidCallback? _onRowMetaChanged;
  final String viewId;
  final List<VoidCallback> _onRowChangedListeners = [];
  final RowCache _rowCache;
  final RowListener _rowListener;
  final RowBackendService _rowBackendSvc;
  bool _isDisposed = false;

  String get rowId => rowMeta.id;
  RowMetaPB get rowMeta => _rowMeta;
  CellMemCache get cellCache => _rowCache.cellCache;

  List<CellContext> loadCells() => _rowCache.loadCells(rowMeta);

  Future<void> initialize() async {
    await _rowBackendSvc.initRow(rowMeta.id);
    _rowListener.start(
      onMetaChanged: (newRowMeta) {
        if (_isDisposed) {
          return;
        }
        _rowMeta = newRowMeta;
        _rowCache.setRowMeta(newRowMeta);
        _onRowMetaChanged?.call();
      },
    );
  }

  void addListener({
    OnRowChanged? onRowChanged,
    VoidCallback? onMetaChanged,
  }) {
    final fn = _rowCache.addListener(
      rowId: rowMeta.id,
      onRowChanged: (context, reasons) {
        if (_isDisposed) {
          return;
        }
        onRowChanged?.call(context, reasons);
      },
    );

    // Add the listener to the list so that we can remove it later.
    _onRowChangedListeners.add(fn);
    _onRowMetaChanged = onMetaChanged;
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await _rowListener.stop();
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }
}
