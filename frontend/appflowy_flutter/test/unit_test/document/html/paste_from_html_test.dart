import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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

    test('sample 4 - paste table from ChatGPT', () {
      final nodes = EditorState.blank().convertHtmlToNodes(tableFromChatGPT);
      final table =
          nodes.where((node) => node.type == SimpleTableBlockKeys.type).first;

      expect(table.columnLength, 3);
      expect(table.rowLength, 7);

      final dividers =
          nodes.where((node) => node.type == DividerBlockKeys.type);
      expect(dividers.length, 5);
    });

    test('sample 5 - paste table from Apple Notes', () {
      checkTable(tableFromAppleNotes);
    });

    test('pastes a single-row HTML table', () {
      final nodes = EditorState.blank().convertHtmlToNodes('''
<table>
  <tr><td>Month</td><td>January</td></tr>
</table>
''');

      expect(nodes.map((node) => node.type), [SimpleTableBlockKeys.type]);
      final table = nodes.single;
      expect(table.rowLength, 1);
      expect(table.columnLength, 2);
      expect(table.getCellText(0, 0), 'Month');
      expect(table.getCellText(0, 1), 'January');
    });

    test('keeps a single-row Google Docs table in a mixed selection', () {
      const url = 'https://example.com/agenda';
      final nodes = EditorState.blank().convertHtmlToNodes('''
<b id="docs-internal-guid-example" style="font-weight: normal;">
  <h2>Planning</h2>
  <div><table><tbody>
    <tr><td><p>Agenda</p></td><td><p><a href="$url">Open</a></p></td></tr>
  </tbody></table></div>
  <ul><li><p>Confirm dates</p></li></ul>
</b>
''');

      expect(nodes.map((node) => node.type), [
        HeadingBlockKeys.type,
        SimpleTableBlockKeys.type,
        BulletedListBlockKeys.type,
      ]);
      expect(nodes.first.delta?.toPlainText(), 'Planning');
      expect(nodes.last.delta?.toPlainText().trim(), 'Confirm dates');

      final table = nodes[1];
      expect(table.rowLength, 1);
      expect(table.columnLength, 2);
      expect(table.getCellText(0, 0), 'Agenda');
      expect(table.getCellText(0, 1), 'Open');
      final linkedCell = table.children.single.children[1].children.single;
      final link = linkedCell.delta?.whereType<TextInsert>().single;
      expect(link?.attributes?[AppFlowyRichTextKeys.href], url);
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
