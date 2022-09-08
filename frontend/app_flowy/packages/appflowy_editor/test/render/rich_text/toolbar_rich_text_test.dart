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

  const singleLineText = "One Line Of Text";

  group('toolbar, heading', (() {
    testWidgets('Select Text, Click toolbar and set style for h1 heading',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final h1 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(h1);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('h1', 1);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.heading, StyleKey.heading: StyleKey.h1});
      expect(node.attributes.heading, 'h1');
    });

    testWidgets('Select Text, Click toolbar and set style for h2 heading',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final h2 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(h2);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('h2', 1);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.heading, StyleKey.heading: StyleKey.h2});
      expect(node.attributes.heading, 'h2');
    });

    testWidgets('Select Text, Click toolbar and set style for h3 heading',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final h3 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(h3);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('h3', 1);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.heading, StyleKey.heading: StyleKey.h3});
      expect(node.attributes.heading, 'h3');
    });
  }));

  group('toolbar, underline', (() {
    testWidgets('Select text, click toolbar and set style for underline',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('underline', 2);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.underline, StyleKey.underline: true});
      expect(node.attributes.underline, true);
    });
  }));

  group('toolbar, bold', (() {
    testWidgets('Select Text, Click Toolbar and set style for bold',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('bold', 2);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.bold, StyleKey.bold: true});
      expect(node.attributes.bold, true);
    });
  }));

  group('toolbar, italic', (() {
    testWidgets('Select Text, Click Toolbar and set style for italic',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('italic', 2);
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
      node.updateAttributes(
          {StyleKey.subtype: StyleKey.italic, StyleKey.italic: true});
      expect(node.attributes.italic, true);
    });
  }));

  group('toolbar, strikethrough', (() {
    testWidgets('Select Text, Click Toolbar and set style for strikethrough',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('strikethrough', 2);
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
      node.updateAttributes({
        StyleKey.subtype: StyleKey.strikethrough,
        StyleKey.strikethrough: true
      });
      expect(node.attributes.strikethrough, true);
    });
  }));

  group('toolbar, code', (() {
    testWidgets('Select Text, Click Toolbar and set style for code',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('code', 2);
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
  }));

  group('toolbar, quote', (() {
    testWidgets('Select Text, Click Toolbar and set style for quote',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('quote', 3);
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
      node.updateAttributes({StyleKey.subtype: StyleKey.quote});
      expect(node.subtype, 'quote');
    });
  }));

  group('toolbar, bullet list', (() {
    testWidgets('Select Text, Click Toolbar and set style for bullet',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();

        editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('bulleted_list', 3);
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
      node.updateAttributes({StyleKey.subtype: StyleKey.bulletedList});
      expect(node.subtype, 'bulleted-list');
    });
  }));

  group('toolbar, link', (() {
    testWidgets('Select Text, Click Toolbar and set style for link',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      final link = "https://google.com";
      editor.insertTextNode(singleLineText);

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('link', 4);
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
      node.updateAttributes({StyleKey.href: link});
      expect(node.attributes.href, link);
    });
  }));

  group('toolbar, highlight', (() {
    testWidgets('Select Text, Click Toolbar and set style for highlighted text',
        (tester) async {
      final editor = tester.editor;
      await editor.startTesting();
      editor.insertTextNode(singleLineText);
      final blue = Colors.blue.shade300;

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [1], offset: singleLineText.length));

      await editor.updateSelection(selection);

      final key = GlobalKey();
      var hit = false;
      final item = toolbar('highlight', 4);
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
      node.updateAttributes({StyleKey.backgroundColor: blue});
      expect(
          node.attributes.toString(), '{backgroundColor: Color(0xff64b5f6)}');
    });
  }));
}

toolbar(String value, int num) {
  return ToolbarItem(
      id: 'appflowy.toolbar.$value',
      type: num,
      iconBuilder: (isHighlight) => FlowySvg(name: 'toolbar/$value'),
      validator: (editorState) => true,
      handler: (editorState, context) {},
      highlightCallback: (editorState) {
        return true;
      });
}

widgetTest(item, key, hit) {
  return ToolbarItemWidget(
      key: key,
      item: item,
      isHighlight: true,
      onPressed: (() {
        hit = true;
      }));
}
