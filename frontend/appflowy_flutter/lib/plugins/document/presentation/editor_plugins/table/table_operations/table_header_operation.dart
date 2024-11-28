import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableHeaderOperation on EditorState {
  /// Toggle the enable header column of the table.
  Future<void> toggleEnableHeaderColumn(Node node, bool enable) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info('toggle enable header column: $enable in table ${node.id}');

    final transaction = this.transaction;
    transaction.updateNode(node, {
      SimpleTableBlockKeys.enableHeaderColumn: enable,
    });
    await apply(transaction);
  }

  /// Toggle the enable header row of the table.
  Future<void> toggleEnableHeaderRow(Node node, bool enable) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info('toggle enable header row: $enable in table ${node.id}');

    final transaction = this.transaction;
    transaction.updateNode(node, {
      SimpleTableBlockKeys.enableHeaderRow: enable,
    });
    await apply(transaction);
  }
}
