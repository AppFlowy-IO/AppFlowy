import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_html.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paste from html:', () {
    test('sample 1 - paste table from Notion', () {
      // | Month | Savings |
      // | -------- | ------- |
      // | January | $250 |
      // | February | $80 |
      // | March | $420 |
      const html = '''<meta charset="utf-8" />
<table id="18196b61-6923-80d7-a184-fbc0352dabc3" class="simple-table">
    <tbody>
        <tr id="18196b61-6923-80a7-b70a-cbae038e1472">
            <td id="Wi`b" class="">Month</td>
            <td id="|EyR" class="">Savings</td>
        </tr>
        <tr id="18196b61-6923-804a-914e-e45f6086a714">
            <td id="Wi`b" class="">January</td>
            <td id="|EyR" class="">\$250</td>
        </tr>
        <tr id="18196b61-6923-80b1-bef5-e15e1d302dfd">
            <td id="Wi`b" class="">February</td>
            <td id="|EyR" class="">\$80</td>
        </tr>
        <tr id="18196b61-6923-8079-aefa-d96c17230695">
            <td id="Wi`b" class="">March</td>
            <td id="|EyR" class="">\$420</td>
        </tr>
    </tbody>
</table>
''';
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
