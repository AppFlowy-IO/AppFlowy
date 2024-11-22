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
      final rowColors = this.rowColors.map((key, value) {
        final iKey = int.parse(key);
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final rowAligns = this.rowAligns.map((key, value) {
        final iKey = int.parse(key);
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      return {
        ...attributes,
        SimpleTableBlockKeys.rowColors: rowColors,
        SimpleTableBlockKeys.rowAligns: rowAligns,
      };
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
      final columnColors = this.columnColors.map((key, value) {
        final iKey = int.parse(key);
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final columnAligns = this.columnAligns.map((key, value) {
        final iKey = int.parse(key);
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final columnWidths = this.columnWidths.map((key, value) {
        final iKey = int.parse(key);
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      return {
        ...attributes,
        SimpleTableBlockKeys.columnColors: columnColors,
        SimpleTableBlockKeys.columnAligns: columnAligns,
        SimpleTableBlockKeys.columnWidths: columnWidths,
      };
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
      MapEntry? duplicatedRowColor;
      MapEntry? duplicatedRowAlign;

      final rowColors = this.rowColors.map((key, value) {
        final iKey = int.parse(key);
        if (iKey == index) {
          duplicatedRowColor = MapEntry(key, value);
        }
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final rowAligns = this.rowAligns.map((key, value) {
        final iKey = int.parse(key);
        if (iKey == index) {
          duplicatedRowAlign = MapEntry(key, value);
        }
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final result = {...attributes};

      if (rowColors.isNotEmpty && duplicatedRowColor != null) {
        result[SimpleTableBlockKeys.rowColors] = {
          ...rowColors,
          duplicatedRowColor!.key: duplicatedRowColor!.value,
        };
      }

      if (rowAligns.isNotEmpty && duplicatedRowAlign != null) {
        result[SimpleTableBlockKeys.rowAligns] = {
          ...rowAligns,
          duplicatedRowAlign!.key: duplicatedRowAlign!.value,
        };
      }

      return result;
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
      MapEntry? duplicatedColumnColor;
      MapEntry? duplicatedColumnAlign;
      MapEntry? duplicatedColumnWidth;

      final columnColors = this.columnColors.map((key, value) {
        final iKey = int.parse(key);
        if (iKey == index) {
          duplicatedColumnColor = MapEntry(key, value);
        }
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final columnAligns = this.columnAligns.map((key, value) {
        final iKey = int.parse(key);
        if (iKey == index) {
          duplicatedColumnAlign = MapEntry(key, value);
        }
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final columnWidths = this.columnWidths.map((key, value) {
        final iKey = int.parse(key);
        if (iKey == index) {
          duplicatedColumnWidth = MapEntry(key, value);
        }
        if (iKey >= index) {
          return MapEntry((iKey + 1).toString(), value);
        }
        return MapEntry(key, value);
      });

      final result = {...attributes};

      if (columnColors.isNotEmpty && duplicatedColumnColor != null) {
        result[SimpleTableBlockKeys.columnColors] = {
          ...columnColors,
          duplicatedColumnColor!.key: duplicatedColumnColor!.value,
        };
      }

      if (columnAligns.isNotEmpty && duplicatedColumnAlign != null) {
        result[SimpleTableBlockKeys.columnAligns] = {
          ...columnAligns,
          duplicatedColumnAlign!.key: duplicatedColumnAlign!.value,
        };
      }

      if (columnWidths.isNotEmpty && duplicatedColumnWidth != null) {
        result[SimpleTableBlockKeys.columnWidths] = {
          ...columnWidths,
          duplicatedColumnWidth!.key: duplicatedColumnWidth!.value,
        };
      }

      return result;
    } catch (e) {
      Log.warn('Failed to map column duplication attributes: $e');
      return attributes;
    }
  }
}
