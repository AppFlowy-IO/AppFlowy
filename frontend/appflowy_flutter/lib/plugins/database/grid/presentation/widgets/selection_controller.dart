import 'package:flutter/widgets.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';

class GridSelectionController extends ChangeNotifier {
  GridSelectionController({required this.getRowInfos});

  final List<RowInfo> Function() getRowInfos;
  final Set<String> _selectedRowIds = {};
  String? _lastSelectedRowId;

  Set<String> get selectedRowIds => _selectedRowIds;
  bool get hasSelection => _selectedRowIds.isNotEmpty;

  bool isSelected(String rowId) => _selectedRowIds.contains(rowId);

  void selectRow(
    String rowId, {
    bool isMultiSelect = false,
    bool isRangeSelect = false,
  }) {
    final rowInfos = getRowInfos();
    if (isRangeSelect && _lastSelectedRowId != null) {
      final startIndex = rowInfos.indexWhere((r) => r.rowId == _lastSelectedRowId);
      final endIndex = rowInfos.indexWhere((r) => r.rowId == rowId);
      if (startIndex != -1 && endIndex != -1) {
        final start = startIndex < endIndex ? startIndex : endIndex;
        final end = startIndex < endIndex ? endIndex : startIndex;
        if (!isMultiSelect) {
          _selectedRowIds.clear();
        }
        for (int i = start; i <= end; i++) {
          _selectedRowIds.add(rowInfos[i].rowId);
        }
      }
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
    final rowInfos = getRowInfos();
    final start = startIndex < endIndex ? startIndex : endIndex;
    final end = startIndex < endIndex ? endIndex : startIndex;

    _selectedRowIds.clear();
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < rowInfos.length) {
        _selectedRowIds.add(rowInfos[i].rowId);
      }
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
}
