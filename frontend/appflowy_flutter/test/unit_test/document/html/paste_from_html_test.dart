import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '_html_samples.dart';

void main() {
  group('paste from html:', () {
    void checkTable(String html) {
      final nodes = EditorState.blank().convertHtmlToNodes(html);
      expect(nodes.length, 1);
      final table = nodes.first;
      expect(table.type, SimpleTableBlockKeys.type);
      expect(table.getCellText(0, 0), 'Month');
      expect(table.getCellText(0, 1), 'Savings');
      expect(table.getCellText(1, 0), 'January');
      expect(table.getCellText(1, 1), '\$250');
      expect(table.getCellText(2, 0), 'February');
      expect(table.getCellText(2, 1), '\$80');
      expect(table.getCellText(3, 0), 'March');
      expect(table.getCellText(3, 1), '\$420');
    }

    test('sample 1 - paste table from Notion', () {
      checkTable(tableFromNotion);
    });

    test('sample 2 - paste table from Google Docs', () {
      checkTable(tableFromGoogleDocs);
    });

    test('sample 3 - paste table from Google Sheets', () {
      checkTable(tableFromGoogleSheets);
    });
  });
}

extension on Node {
  String getCellText(
    int row,
    int column, {
    int index = 0,
  }) {
    return children[row]
            .children[column]
            .children[index]
            .delta
            ?.toPlainText() ??
        '';
  }
}
