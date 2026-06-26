import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';

class GridSelectionController extends ChangeNotifier {
  GridSelectionController({required this.getRowInfos});

  final List<RowInfo> Function() getRowInfos;
  final Set<String> _selectedRowIds = {};
  String? _lastSelectedRowId;

  UnmodifiableSetView<String> get selectedRowIds =>
      UnmodifiableSetView(_selectedRowIds);
  bool get hasSelection => _selectedRowIds.isNotEmpty;

  bool isSelected(String rowId) => _selectedRowIds.contains(rowId);

  void selectRow(
    String rowId, {
    bool isMultiSelect = false,
    bool isRangeSelect = false,
  }) {
    if (isRangeSelect && _lastSelectedRowId != null) {
      final rowInfos = getRowInfos();
      final startIndex =
          rowInfos.indexWhere((r) => r.rowId == _lastSelectedRowId);
      final endIndex = rowInfos.indexWhere((r) => r.rowId == rowId);
      if (startIndex != -1 && endIndex != -1) {
        _applyRange(startIndex, endIndex, clearFirst: !isMultiSelect);
      }
      // Don't update _lastSelectedRowId on range select so subsequent
      // shift-clicks extend from the original anchor.
    } else if (isMultiSelect) {
      if (_selectedRowIds.contains(rowId)) {
        _selectedRowIds.remove(rowId);
      } else {
        _selectedRowIds.add(rowId);
      }
      _lastSelectedRowId = rowId;
    } else {
      _selectedRowIds.clear();
      _selectedRowIds.add(rowId);
      _lastSelectedRowId = rowId;
    }
    notifyListeners();
  }

  void selectRange(int startIndex, int endIndex) {
    _applyRange(startIndex, endIndex, clearFirst: true);
    // Update _lastSelectedRowId to the end of the range so subsequent
    // shift-clicks anchor correctly after a drag.
    final rowInfos = getRowInfos();
    final clampedEnd = endIndex.clamp(0, rowInfos.length - 1);
    if (rowInfos.isNotEmpty) {
      _lastSelectedRowId = rowInfos[clampedEnd].rowId;
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedRowIds.isNotEmpty) {
      _selectedRowIds.clear();
      _lastSelectedRowId = null;
      notifyListeners();
    }
  }

  void selectAll() {
    final rowInfos = getRowInfos();
    _selectedRowIds.clear();
    _selectedRowIds.addAll(rowInfos.map((r) => r.rowId));
    if (rowInfos.isNotEmpty) {
      _lastSelectedRowId = rowInfos.first.rowId;
    }
    notifyListeners();
  }

  /// Shared helper that selects all rows between [startIndex] and [endIndex].
  void _applyRange(int startIndex, int endIndex, {required bool clearFirst}) {
    final rowInfos = getRowInfos();
    final start = startIndex < endIndex ? startIndex : endIndex;
    final end = startIndex < endIndex ? endIndex : startIndex;

    if (clearFirst) {
      _selectedRowIds.clear();
    }
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < rowInfos.length) {
        _selectedRowIds.add(rowInfos[i].rowId);
      }
    }
  }
}
