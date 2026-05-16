import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableHeaderOperation on EditorState {
  /// Toggle the enable header column of the table.
  Future<void> toggleEnableHeaderColumn({
    required Node tableNode,
    required bool enable,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info(
      'toggle enable header column: $enable in table ${tableNode.id}',
    );

    final columnColors = tableNode.columnColors;

    final transaction = this.transaction;
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.enableHeaderColumn: enable,
      // remove the previous background color if the header column is enable again
      if (enable)
        SimpleTableBlockKeys.columnColors: columnColors
          ..removeWhere((key, _) => key == '0'),
    });
    await apply(transaction);
  }

  /// Toggle the enable header row of the table.
  Future<void> toggleEnableHeaderRow({
    required Node tableNode,
    required bool enable,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info('toggle enable header row: $enable in table ${tableNode.id}');

    final rowColors = tableNode.rowColors;

    final transaction = this.transaction;
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.enableHeaderRow: enable,
      // remove the previous background color if the header row is enable again
      if (enable)
        SimpleTableBlockKeys.rowColors: rowColors
          ..removeWhere((key, _) => key == '0'),
    });
    await apply(transaction);
  }
}
