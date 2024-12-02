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
}

extension TableMapOperation on Node {
  Attributes? mapTableAttributes(
    Node node, {
    required TableMapOperationType type,
    required int index,
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
    }

    // clear the attributes that are null
    attributes?.removeWhere((key, value) => value == null);

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
