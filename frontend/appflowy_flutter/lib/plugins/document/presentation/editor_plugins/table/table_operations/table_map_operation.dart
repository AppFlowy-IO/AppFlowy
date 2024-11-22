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
      case TableMapOperationType.duplicateRow:
        return _mapRowDuplicationAttributes(index);
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

      return {
        ...attributes,
        SimpleTableBlockKeys.rowColors: {
          ...rowColors,
          duplicatedRowColor?.key: duplicatedRowColor?.value,
        },
        SimpleTableBlockKeys.rowAligns: {
          ...rowAligns,
          duplicatedRowAlign?.key: duplicatedRowAlign?.value,
        },
      };
    } catch (e) {
      Log.warn('Failed to map row insertion attributes: $e');
      return attributes;
    }
  }
}
