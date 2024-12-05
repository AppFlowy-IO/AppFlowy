import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

enum TableMapOperationType {
  insertRow,
  deleteRow,
  insertColumn,
  deleteColumn,
  duplicateRow,
  duplicateColumn,
  reorderColumn,
  reorderRow,
}

extension TableMapOperation on Node {
  Attributes? mapTableAttributes(
    Node node, {
    required TableMapOperationType type,
    required int index,
    // Only used for reorder column operation
    int? toIndex,
  }) {
    assert(this.type == SimpleTableBlockKeys.type);

    if (this.type != SimpleTableBlockKeys.type) {
      return null;
    }

    Attributes? attributes;

    switch (type) {
      case TableMapOperationType.insertRow:
        attributes = _mapRowInsertionAttributes(index);
      case TableMapOperationType.insertColumn:
        attributes = _mapColumnInsertionAttributes(index);
      case TableMapOperationType.duplicateRow:
        attributes = _mapRowDuplicationAttributes(index);
      case TableMapOperationType.duplicateColumn:
        attributes = _mapColumnDuplicationAttributes(index);
      case TableMapOperationType.deleteRow:
        attributes = _mapRowDeletionAttributes(index);
      case TableMapOperationType.deleteColumn:
        attributes = _mapColumnDeletionAttributes(index);
      case TableMapOperationType.reorderColumn:
        if (toIndex != null) {
          attributes = _mapColumnReorderingAttributes(index, toIndex);
        }
      case TableMapOperationType.reorderRow:
        if (toIndex != null) {
          attributes = _mapRowReorderingAttributes(index, toIndex);
        }
    }

    // clear the attributes that are null
    attributes?.removeWhere(
      (key, value) => value == null,
    );

    return attributes;
  }

  /// Map the attributes of a row insertion operation.
  ///
  /// When inserting a row, the attributes of the table after the index should be updated
  /// For example:
  /// Before:
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  | ← insert a new row here
  ///
  /// The original attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///   }
  /// }
  ///
  /// Insert a row at index 1:
  /// |  0  |  1  |  2  |
  /// |     |     |     | ← new row
  /// |  3  |  4  |  5  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     2: "#00FF00", ← The attributes of the original second row
  ///   }
  /// }
  Attributes? _mapRowInsertionAttributes(int index) {
    final attributes = this.attributes;
    try {
      final rowColors = _remapSource(
        this.rowColors,
        index,
        comparator: (iKey, index) => iKey >= index,
      );

      final rowAligns = _remapSource(
        this.rowAligns,
        index,
        comparator: (iKey, index) => iKey >= index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.rowColors,
            rowColors,
          )
          .mergeValues(
            SimpleTableBlockKeys.rowAligns,
            rowAligns,
          );
    } catch (e) {
      Log.warn('Failed to map row insertion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a column insertion operation.
  ///
  /// When inserting a column, the attributes of the table after the index should be updated
  /// For example:
  /// Before:
  /// |  0  |  1  |
  /// |  2  |  3  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///   }
  /// }
  ///
  /// Insert a column at index 1:
  /// |  0  |     |  1  |
  /// |  2  |     |  3  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     2: "#00FF00", ← The attributes of the original second column
  ///   }
  /// }
  Attributes? _mapColumnInsertionAttributes(int index) {
    final attributes = this.attributes;
    try {
      final columnColors = _remapSource(
        this.columnColors,
        index,
        comparator: (iKey, index) => iKey >= index,
      );

      final columnAligns = _remapSource(
        this.columnAligns,
        index,
        comparator: (iKey, index) => iKey >= index,
      );

      final columnWidths = _remapSource(
        this.columnWidths,
        index,
        comparator: (iKey, index) => iKey >= index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.columnColors,
            columnColors,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnAligns,
            columnAligns,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnWidths,
            columnWidths,
          );
    } catch (e) {
      Log.warn('Failed to map row insertion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a row duplication operation.
  ///
  /// When duplicating a row, the attributes of the table after the index should be updated
  /// For example:
  /// Before:
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///   }
  /// }
  ///
  /// Duplicate the row at index 1:
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  |
  /// |  3  |  4  |  5  | ← duplicated row
  ///
  /// The new attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///     2: "#00FF00", ← The attributes of the original second row
  ///   }
  /// }
  Attributes? _mapRowDuplicationAttributes(int index) {
    final attributes = this.attributes;
    try {
      final (rowColors, duplicatedRowColor) = _findDuplicatedEntryAndRemap(
        this.rowColors,
        index,
      );

      final (rowAligns, duplicatedRowAlign) = _findDuplicatedEntryAndRemap(
        this.rowAligns,
        index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.rowColors,
            rowColors,
            duplicatedEntry: duplicatedRowColor,
          )
          .mergeValues(
            SimpleTableBlockKeys.rowAligns,
            rowAligns,
            duplicatedEntry: duplicatedRowAlign,
          );
    } catch (e) {
      Log.warn('Failed to map row insertion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a column duplication operation.
  ///
  /// When duplicating a column, the attributes of the table after the index should be updated
  /// For example:
  /// Before:
  /// |  0  |  1  |
  /// |  2  |  3  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///   }
  /// }
  ///
  /// Duplicate the column at index 1:
  /// |  0  |  1  |  1  | ← duplicated column
  /// |  2  |  3  |  2  | ← duplicated column
  ///
  /// The new attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///     2: "#00FF00", ← The attributes of the original second column
  ///   }
  /// }
  Attributes? _mapColumnDuplicationAttributes(int index) {
    final attributes = this.attributes;
    try {
      final (columnColors, duplicatedColumnColor) =
          _findDuplicatedEntryAndRemap(
        this.columnColors,
        index,
      );

      final (columnAligns, duplicatedColumnAlign) =
          _findDuplicatedEntryAndRemap(
        this.columnAligns,
        index,
      );

      final (columnWidths, duplicatedColumnWidth) =
          _findDuplicatedEntryAndRemap(
        this.columnWidths,
        index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.columnColors,
            columnColors,
            duplicatedEntry: duplicatedColumnColor,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnAligns,
            columnAligns,
            duplicatedEntry: duplicatedColumnAlign,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnWidths,
            columnWidths,
            duplicatedEntry: duplicatedColumnWidth,
          );
    } catch (e) {
      Log.warn('Failed to map column duplication attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a column deletion operation.
  ///
  /// When deleting a column, the attributes of the table after the index should be updated
  ///
  /// For example:
  /// Before:
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     2: "#00FF00",
  ///   }
  /// }
  ///
  /// Delete the column at index 1:
  /// |  0  |  2  |
  /// |  3  |  5  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00", ← The attributes of the original second column
  ///   }
  /// }
  Attributes? _mapColumnDeletionAttributes(int index) {
    final attributes = this.attributes;
    try {
      final columnColors = _remapSource(
        this.columnColors,
        index,
        increment: false,
        comparator: (iKey, index) => iKey > index,
        filterIndex: index,
      );
      final columnAligns = _remapSource(
        this.columnAligns,
        index,
        increment: false,
        comparator: (iKey, index) => iKey > index,
        filterIndex: index,
      );
      final columnWidths = _remapSource(
        this.columnWidths,
        index,
        increment: false,
        comparator: (iKey, index) => iKey > index,
        filterIndex: index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.columnColors,
            columnColors,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnAligns,
            columnAligns,
          )
          .mergeValues(
            SimpleTableBlockKeys.columnWidths,
            columnWidths,
          );
    } catch (e) {
      Log.warn('Failed to map column deletion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a row deletion operation.
  ///
  /// When deleting a row, the attributes of the table after the index should be updated
  ///
  /// For example:
  /// Before:
  /// |  0  |  1  |  2  | ← delete this row
  /// |  3  |  4  |  5  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///   }
  /// }
  ///
  /// Delete the row at index 0:
  /// |  3  |  4  |  5  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#00FF00",
  ///   }
  /// }
  Attributes? _mapRowDeletionAttributes(int index) {
    final attributes = this.attributes;
    try {
      final rowColors = _remapSource(
        this.rowColors,
        index,
        increment: false,
        comparator: (iKey, index) => iKey > index,
        filterIndex: index,
      );
      final rowAligns = _remapSource(
        this.rowAligns,
        index,
        increment: false,
        comparator: (iKey, index) => iKey > index,
        filterIndex: index,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.rowColors,
            rowColors,
          )
          .mergeValues(
            SimpleTableBlockKeys.rowAligns,
            rowAligns,
          );
    } catch (e) {
      Log.warn('Failed to map row deletion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a column reordering operation.
  ///
  ///
  /// Examples:
  /// Case 1:
  ///
  /// When reordering a column, if the from index is greater than the to index,
  /// the attributes of the table before the from index should be updated.
  ///
  /// Before:
  ///          ↓ reorder this column from index 1 to index 0
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///     2: "#0000FF",
  ///   }
  /// }
  ///
  /// After reordering:
  /// |  1  |  0  |  2  |
  /// |  4  |  3  |  5  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "rowColors": {
  ///     0: "#00FF00", ← The attributes of the original second column
  ///     1: "#FF0000", ← The attributes of the original first column
  ///     2: "#0000FF",
  ///   }
  /// }
  ///
  /// Case 2:
  ///
  /// When reordering a column, if the from index is less than the to index,
  /// the attributes of the table after the from index should be updated.
  ///
  /// Before:
  ///          ↓ reorder this column from index 1 to index 2
  /// |  0  |  1  |  2  |
  /// |  3  |  4  |  5  |
  ///
  /// The original attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#00FF00",
  ///     2: "#0000FF",
  ///   }
  /// }
  ///
  /// After reordering:
  /// |  0  |  2  |  1  |
  /// |  3  |  5  |  4  |
  ///
  /// The new attributes of the table:
  /// {
  ///   "columnColors": {
  ///     0: "#FF0000",
  ///     1: "#0000FF", ← The attributes of the original third column
  ///     2: "#00FF00", ← The attributes of the original second column
  ///   }
  /// }
  Attributes? _mapColumnReorderingAttributes(int fromIndex, int toIndex) {
    final attributes = this.attributes;
    try {
      final duplicatedColumnColor = this.columnColors[fromIndex.toString()];
      final duplicatedColumnAlign = this.columnAligns[fromIndex.toString()];
      final duplicatedColumnWidth = this.columnWidths[fromIndex.toString()];

      final columnColors = _remapSource(
        this.columnColors,
        fromIndex,
        increment: fromIndex > toIndex,
        comparator: (iKey, index) {
          if (fromIndex > toIndex) {
            return iKey < fromIndex && iKey >= toIndex;
          } else {
            return iKey > fromIndex && iKey <= toIndex;
          }
        },
        filterIndex: fromIndex,
      );

      final columnAligns = _remapSource(
        this.columnAligns,
        fromIndex,
        increment: fromIndex > toIndex,
        comparator: (iKey, index) {
          if (fromIndex > toIndex) {
            return iKey < fromIndex && iKey >= toIndex;
          } else {
            return iKey > fromIndex && iKey <= toIndex;
          }
        },
        filterIndex: fromIndex,
      );

      final columnWidths = _remapSource(
        this.columnWidths,
        fromIndex,
        increment: fromIndex > toIndex,
        comparator: (iKey, index) {
          if (fromIndex > toIndex) {
            return iKey < fromIndex && iKey >= toIndex;
          } else {
            return iKey > fromIndex && iKey <= toIndex;
          }
        },
        filterIndex: fromIndex,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.columnColors,
            columnColors,
            duplicatedEntry: MapEntry(
              toIndex.toString(),
              duplicatedColumnColor,
            ),
          )
          .mergeValues(
            SimpleTableBlockKeys.columnAligns,
            columnAligns,
            duplicatedEntry: MapEntry(
              toIndex.toString(),
              duplicatedColumnAlign,
            ),
          )
          .mergeValues(
            SimpleTableBlockKeys.columnWidths,
            columnWidths,
            duplicatedEntry: MapEntry(
              toIndex.toString(),
              duplicatedColumnWidth,
            ),
          );
    } catch (e) {
      Log.warn('Failed to map column deletion attributes: $e');
      return attributes;
    }
  }

  /// Map the attributes of a row reordering operation.
  ///
  /// See [_mapColumnReorderingAttributes] for more details.
  Attributes? _mapRowReorderingAttributes(int fromIndex, int toIndex) {
    final attributes = this.attributes;
    try {
      final duplicatedRowColor = this.rowColors[fromIndex.toString()];
      final duplicatedRowAlign = this.rowAligns[fromIndex.toString()];

      final rowColors = _remapSource(
        this.rowColors,
        fromIndex,
        increment: fromIndex > toIndex,
        comparator: (iKey, index) {
          if (fromIndex > toIndex) {
            return iKey < fromIndex && iKey >= toIndex;
          } else {
            return iKey > fromIndex && iKey <= toIndex;
          }
        },
        filterIndex: fromIndex,
      );

      final rowAligns = _remapSource(
        this.rowAligns,
        fromIndex,
        increment: fromIndex > toIndex,
        comparator: (iKey, index) {
          if (fromIndex > toIndex) {
            return iKey < fromIndex && iKey >= toIndex;
          } else {
            return iKey > fromIndex && iKey <= toIndex;
          }
        },
        filterIndex: fromIndex,
      );

      return attributes
          .mergeValues(
            SimpleTableBlockKeys.rowColors,
            rowColors,
            duplicatedEntry: MapEntry(
              toIndex.toString(),
              duplicatedRowColor,
            ),
          )
          .mergeValues(
            SimpleTableBlockKeys.rowAligns,
            rowAligns,
            duplicatedEntry: MapEntry(
              toIndex.toString(),
              duplicatedRowAlign,
            ),
          );
    } catch (e) {
      Log.warn('Failed to map row reordering attributes: $e');
      return attributes;
    }
  }
}

/// Find the duplicated entry and remap the source.
///
/// All the entries after the index will be remapped to the new index.
(Map<String, dynamic> newSource, MapEntry? duplicatedEntry)
    _findDuplicatedEntryAndRemap(
  Map<String, dynamic> source,
  int index, {
  bool increment = true,
}) {
  MapEntry? duplicatedEntry;
  final newSource = source.map((key, value) {
    final iKey = int.parse(key);
    if (iKey == index) {
      duplicatedEntry = MapEntry(key, value);
    }
    if (iKey >= index) {
      return MapEntry((iKey + (increment ? 1 : -1)).toString(), value);
    }
    return MapEntry(key, value);
  });
  return (newSource, duplicatedEntry);
}

/// Remap the source to the new index.
///
/// All the entries after the index will be remapped to the new index.
Map<String, dynamic> _remapSource(
  Map<String, dynamic> source,
  int index, {
  bool increment = true,
  required bool Function(int iKey, int index) comparator,
  int? filterIndex,
}) {
  var newSource = {...source};
  if (filterIndex != null) {
    newSource.remove(filterIndex.toString());
  }
  newSource = newSource.map((key, value) {
    final iKey = int.parse(key);
    if (comparator(iKey, index)) {
      return MapEntry((iKey + (increment ? 1 : -1)).toString(), value);
    }
    return MapEntry(key, value);
  });
  return newSource;
}

extension TableMapOperationAttributes on Attributes {
  Attributes mergeValues(
    String key,
    Map<String, dynamic> newSource, {
    MapEntry? duplicatedEntry,
  }) {
    final result = {...this};

    if (duplicatedEntry != null) {
      newSource[duplicatedEntry.key] = duplicatedEntry.value;
    }

    result[key] = newSource;

    return result;
  }
}
