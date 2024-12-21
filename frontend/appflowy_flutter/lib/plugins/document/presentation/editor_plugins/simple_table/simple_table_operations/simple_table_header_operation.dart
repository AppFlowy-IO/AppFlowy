import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
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

    final transaction = this.transaction;
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.enableHeaderColumn: enable,
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

    final transaction = this.transaction;
    transaction.updateNode(tableNode, {
      SimpleTableBlockKeys.enableHeaderRow: enable,
    });
    await apply(transaction);
  }
}
