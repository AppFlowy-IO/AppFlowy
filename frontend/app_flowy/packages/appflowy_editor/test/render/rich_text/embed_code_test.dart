import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/editor_state_extensions.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item_widget.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('toolbar_item.dart', () {
    testWidgets('Select Text, Click Toolbar and set style', (tester) async {
      const text = 'Embed Code in AppFlowy';
      final editor = tester.editor;

      await editor.startTesting();
      editor.insertTextNode(text);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [1], offset: text.length),
      );

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = ToolbarItem(
        id: 'appflowy.toolbar.embed_code',
        type: 2,
        iconBuilder: (isHighlight) => const FlowySvg(name: 'toolbar/code'),
        validator: _onlyShowInSingleTextSelection,
        highlightCallback: (editorState) => _allSatisfy(
            editorState, StyleKey.code, (value) => value == StyleKey.code),
        handler: (editorState, context) => formatEmbedCode(editorState),
      );

      final widget = ToolbarItemWidget(
          key: key,
          item: item,
          isHighlight: true,
          onPressed: (() {
            hit = true;
          }));

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: widget,
          ),
        ),
      );
      expect(find.byKey(key), findsOneWidget);

      await tester.tap(find.byKey(key));
      expect(hit, true);
      node.updateAttributes({StyleKey.subtype: StyleKey.code});
      expect(node.subtype, 'code');
    });
  });
}

ToolbarItemValidator _onlyShowInSingleTextSelection = (editorState) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  return (nodes.length == 1 && nodes.first is TextNode);
};

bool _allSatisfy(
  EditorState editorState,
  String styleKey,
  bool Function(dynamic value) test,
) {
  final selection = editorState.service.selectionService.currentSelection.value;
  return selection != null &&
      editorState.selectedTextNodes.allSatisfyInSelection(
        selection,
        styleKey,
        test,
      );
}
