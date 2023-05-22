import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class EditorMigration {
  // AppFlowy 0.1.x -> 0.2
  //
  // The cover node has been deprecated, and use page/attributes/cover instead.
  // cover node -> page/attributes/cover
  //
  // mark the textNode deprecated. use paragraph node instead.
  // text node -> paragraph node
  // delta -> attributes/delta
  //
  // mark the subtype deprecated. use type instead.
  // for example, text/checkbox -> checkbox_list
  //
  // some attribute keys.
  // ...
  static Document migrateDocument(String json) {
    final map = jsonDecode(json);
    assert(map['document'] != null);
    final documentV0 = Map<String, Object>.from(map['document'] as Map);
    final rootV0 = NodeV0.fromJson(documentV0);
    final root = migrateNode(rootV0);
    return Document(root: root);
  }

  static Node migrateNode(NodeV0 nodeV0) {
    Node? node;
    final children = nodeV0.children.map((e) => migrateNode(e));
    final id = nodeV0.id;
    if (id == 'editor') {
      node = documentNode(children: children);
    } else if (id == 'cover') {
      node = paragraphNode(text: 'cover');
    } else if (id == 'callout') {
      final emoji = nodeV0.attributes['emoji'] ?? '📌';
      final text = children
          .whereType<TextNodeV0>()
          .fold('', (p, e) => p + e.toPlainText());
      node = calloutNode(
        emoji: emoji,
        delta: Delta()
          ..insert(text)
          ..toJson(),
      );
    } else if (id == 'divider') {
      // divider -> divider
      node = dividerNode();
    } else if (id == 'math_equation') {
      // math_equation -> math_equation
      final formula = nodeV0.attributes['math_equation'] ?? '';
      node = mathEquationNode(formula: formula);
    } else if (id == 'code_block') {
      // code_block -> code
      final code = nodeV0.attributes['code_block'] ?? '';
      node = codeBlockNode(
        delta: Delta()
          ..insert(code)
          ..toJson(),
      );
    } else if (nodeV0 is TextNodeV0) {
      final delta = migrateDelta(nodeV0.delta).toJson();
      final attributes = {'delta': delta};
      if (id == 'text') {
        // text -> paragraph
        node = paragraphNode(
          attributes: attributes,
          children: children,
        );
      } else if (nodeV0.id == 'text/heading') {
        // text/heading -> heading
        final heading = nodeV0.attributes.heading?.replaceAll('h', '');
        final level = int.tryParse(heading ?? '') ?? 1;
        node = headingNode(
          level: level,
          attributes: attributes,
        );
      } else if (id == 'text/checkbox') {
        // text/checkbox -> todo_list
        final checked = nodeV0.attributes.check;
        node = todoListNode(
          checked: checked,
          attributes: attributes,
          children: children,
        );
      } else if (id == 'text/quote') {
        // text/quote -> quote
        node = quoteNode(attributes: attributes);
      } else if (id == 'text/number-list') {
        // text/number-list -> numbered_list
        node = numberedListNode(
          attributes: attributes,
          children: children,
        );
      } else if (id == 'text/bulleted-list') {
        // text/bulleted-list -> bulleted_list
        node = bulletedListNode(
          attributes: attributes,
          children: children,
        );
      }
    } else {
      assert(node != null);
    }
    return node ?? paragraphNode(text: jsonEncode(nodeV0.toJson()));
  }

  // migrate the attributes.
  // backgroundColor -> highlightColor
  // color -> textColor
  static Delta migrateDelta(Delta delta) {
    final textInserts = delta.whereType<TextInsert>();
    for (final element in textInserts) {
      final attributes = element.attributes;
      if (attributes == null) {
        continue;
      }
      const backgroundColor = 'backgroundColor';
      if (attributes.containsKey(backgroundColor)) {
        attributes['highlightColor'] = attributes[backgroundColor];
        attributes.remove(backgroundColor);
      }
      const color = 'color';
      if (attributes.containsKey(color)) {
        attributes['textColor'] = attributes[color];
        attributes.remove(color);
      }
    }
    return Delta(operations: textInserts.toList());
  }
}
