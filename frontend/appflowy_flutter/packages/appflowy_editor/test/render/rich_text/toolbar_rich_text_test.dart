import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_item_widget.dart';
import 'package:appflowy_editor/src/render/toolbar/toolbar_widget.dart';
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
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final h1 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(h1);

      expect(find.byType(ToolbarWidget), findsOneWidget);

      final h1Button = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.h1';
        }
        return false;
      });

      expect(h1Button, findsOneWidget);
      await tester.tap(h1Button);
      await tester.pumpAndSettle();

      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.attributes.heading, 'h1');
    });

    testWidgets('Select Text, Click toolbar and set style for h2 heading',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final h2 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(h2);
      expect(find.byType(ToolbarWidget), findsOneWidget);

      final h2Button = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.h2';
        }
        return false;
      });
      expect(h2Button, findsOneWidget);
      await tester.tap(h2Button);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.attributes.heading, 'h2');
    });

    testWidgets('Select Text, Click toolbar and set style for h3 heading',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final h3 = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(h3);
      expect(find.byType(ToolbarWidget), findsOneWidget);

      final h3Button = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.h3';
        }
        return false;
      });
      expect(h3Button, findsOneWidget);
      await tester.tap(h3Button);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.attributes.heading, 'h3');
    });
  }));

  group('toolbar, underline', (() {
    testWidgets('Select text, click toolbar and set style for underline',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final underline = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(underline);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final underlineButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.underline';
        }
        return false;
      });

      expect(underlineButton, findsOneWidget);
      await tester.tap(underlineButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      // expect(node.attributes.underline, true);
      expect(node.allSatisfyUnderlineInSelection(underline), true);
    });
  }));

  group('toolbar, bold', (() {
    testWidgets('Select Text, Click Toolbar and set style for bold',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final bold = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(bold);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final boldButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.bold';
        }
        return false;
      });

      expect(boldButton, findsOneWidget);
      await tester.tap(boldButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.allSatisfyBoldInSelection(bold), true);
    });
  }));

  group('toolbar, italic', (() {
    testWidgets('Select Text, Click Toolbar and set style for italic',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final italic = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(italic);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final italicButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.italic';
        }
        return false;
      });

      expect(italicButton, findsOneWidget);
      await tester.tap(italicButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.allSatisfyItalicInSelection(italic), true);
    });
  }));

  group('toolbar, strikethrough', (() {
    testWidgets('Select Text, Click Toolbar and set style for strikethrough',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final strikeThrough = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(strikeThrough);

      expect(find.byType(ToolbarWidget), findsOneWidget);
      final strikeThroughButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.strikethrough';
        }
        return false;
      });

      expect(strikeThroughButton, findsOneWidget);
      await tester.tap(strikeThroughButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.allSatisfyStrikethroughInSelection(strikeThrough), true);
    });
  }));

  group('toolbar, code', (() {
    testWidgets('Select Text, Click Toolbar and set style for code',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final code = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(code);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final codeButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.code';
        }
        return false;
      });

      expect(codeButton, findsOneWidget);
      await tester.tap(codeButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(
        node.allSatisfyInSelection(
          code,
          BuiltInAttributeKey.code,
          (value) {
            return value == true;
          },
        ),
        true,
      );
    });
  }));

  group('toolbar, quote', (() {
    testWidgets('Select Text, Click Toolbar and set style for quote',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final quote = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(quote);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final quoteButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.quote';
        }
        return false;
      });
      expect(quoteButton, findsOneWidget);
      await tester.tap(quoteButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.subtype, 'quote');
    });
  }));

  group('toolbar, bullet list', (() {
    testWidgets('Select Text, Click Toolbar and set style for bullet',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final bulletList = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(bulletList);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final bulletListButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.bulleted_list';
        }
        return false;
      });

      expect(bulletListButton, findsOneWidget);
      await tester.tap(bulletListButton);
      await tester.pumpAndSettle();
      final node = editor.nodeAtPath([0]) as TextNode;
      expect(node.subtype, 'bulleted-list');
    });
  }));

  group('toolbar, highlight', (() {
    testWidgets('Select Text, Click Toolbar and set style for highlighted text',
        (tester) async {
      // FIXME: Use a const value instead of the magic string.
      const blue = '0x6000BCF0';
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
          start: Position(path: [0], offset: 0),
          end: Position(path: [0], offset: singleLineText.length));

      await editor.updateSelection(selection);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final highlightButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.highlight';
        }
        return false;
      });
      expect(highlightButton, findsOneWidget);
      await tester.tap(highlightButton);
      await tester.pumpAndSettle();
      expect(
        node.allSatisfyInSelection(
          selection,
          BuiltInAttributeKey.backgroundColor,
          (value) {
            return value == blue;
          },
        ),
        true,
      );
    });
  }));

  group('toolbar, color picker', (() {
    testWidgets(
        'Select Text, Click Toolbar and set color for the selected text',
        (tester) async {
      final editor = tester.editor..insertTextNode(singleLineText);
      await editor.startTesting();

      final node = editor.nodeAtPath([0]) as TextNode;
      final selection = Selection(
        start: Position(path: [0], offset: 0),
        end: Position(path: [0], offset: singleLineText.length),
      );

      await editor.updateSelection(selection);
      expect(find.byType(ToolbarWidget), findsOneWidget);
      final colorButton = find.byWidgetPredicate((widget) {
        if (widget is ToolbarItemWidget) {
          return widget.item.id == 'appflowy.toolbar.color';
        }
        return false;
      });
      expect(colorButton, findsOneWidget);
      await tester.tap(colorButton);
      await tester.pumpAndSettle();
      // select a yellow color
      final yellowButton = find.text('Yellow');
      await tester.tap(yellowButton);
      await tester.pumpAndSettle();
      expect(
        node.allSatisfyInSelection(
          selection,
          BuiltInAttributeKey.color,
          (value) {
            return value == Colors.yellow.toHex();
          },
        ),
        true,
      );
    });
  }));
}

extension on Color {
  String toHex() {
    return '0x${value.toRadixString(16)}';
  }
}
