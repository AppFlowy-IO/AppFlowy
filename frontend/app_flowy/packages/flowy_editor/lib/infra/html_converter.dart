import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as html;

class HTMLConverter {
  final html.Document _document;

  HTMLConverter(String htmlString) : _document = parse(htmlString);

  List<Node> toNodes() {
    final result = <Node>[];
    final delta = Delta();

    final bodyChildren = _document.body?.children ?? [];
    for (final child in bodyChildren) {
      delta.insert(child.text);
    }

    if (delta.operations.isNotEmpty) {
      result.add(TextNode(type: "text", delta: delta));
    }

    return result;
  }
}
