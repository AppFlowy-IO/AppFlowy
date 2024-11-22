import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
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

    switch (type) {
      case TableMapOperationType.insertRow:
        return _mapRowInsertionAttributes(index);
      case TableMapOperationType.insertColumn:
        return _mapColumnInsertionAttributes(index);
      case TableMapOperationType.duplicateRow:
        return _mapRowDuplicationAttributes(index);
      case TableMapOperationType.duplicateColumn:
        return _mapColumnDuplicationAttributes(index);
      case TableMapOperationType.deleteRow:
      // return _mapRowDeletionAttributes(index);
      case TableMapOperationType.deleteColumn:
      // return _mapColumnDeletionAttributes(index);
      default:
        return null;
    }
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
      );

      final rowAligns = _remapSource(
        this.rowAligns,
        index,
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
      );

      final columnAligns = _remapSource(
        this.columnAligns,
        index,
      );

      final columnWidths = _remapSource(
        this.columnWidths,
        index,
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
}

/// Find the duplicated entry and remap the source.
///
/// All the entries after the index will be remapped to the new index.
(Map<String, dynamic> newSource, MapEntry? duplicatedEntry)
    _findDuplicatedEntryAndRemap(
  Map<String, dynamic> source,
  int index,
) {
  MapEntry? duplicatedEntry;
  final newSource = source.map((key, value) {
    final iKey = int.parse(key);
    if (iKey == index) {
      duplicatedEntry = MapEntry(key, value);
    }
    if (iKey >= index) {
      return MapEntry((iKey + 1).toString(), value);
    }
    return MapEntry(key, value);
  });
  return (newSource, duplicatedEntry);
}

/// Remap the source to the new index.
///
/// All the entries after the index will be remapped to the new index.
Map<String, dynamic> _remapSource(Map<String, dynamic> source, int index) {
  return source.map((key, value) {
    final iKey = int.parse(key);
    if (iKey >= index) {
      return MapEntry((iKey + 1).toString(), value);
    }
    return MapEntry(key, value);
  });
}

extension on Attributes {
  Attributes mergeValues(
    String key,
    Map<String, dynamic> newSource, {
    MapEntry? duplicatedEntry,
  }) {
    final result = {...this};

    if (newSource.isNotEmpty) {
      result[key] = {
        ...newSource,
        if (duplicatedEntry != null) duplicatedEntry.key: duplicatedEntry.value,
      };
    }

    return result;
  }
}
