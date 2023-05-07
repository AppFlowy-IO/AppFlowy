import 'dart:convert';

import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show Document, Node, Attributes, Delta;

extension AppFlowyEditor on DocumentDataPB2 {
  Document toDocument() {
    final rootId = pageId;
    final root = buildNode(rootId);
    return Document(root: root);
  }

  Node buildNode(String id) {
    final block = blocks[id]!; // TODO: don't use force unwrap
    final childrenId = block.childrenId;
    final childrenIds = meta.childrenMap[childrenId]?.children;
    final children = <Node>[];
    if (childrenIds != null && childrenIds.isNotEmpty) {
      children.addAll(childrenIds.map((e) => buildNode(e)));
    }
    return block.toNode(children: children);
  }
}

extension BlockToNode on BlockPB {
  Node toNode({
    Iterable<Node>? children,
  }) {
    return Node(
      id: id,
      type: _typeAdapter(ty),
      attributes: _dataAdapter(ty, data),
      children: children ?? [],
    );
  }

  String _typeAdapter(String ty) {
    final adapter = {
      'page': 'document',
      'text': 'paragraph',
    };
    return adapter[ty] ?? ty;
  }

  Attributes _dataAdapter(String ty, String data) {
    final map = Attributes.from(jsonDecode(data));
    final adapter = {
      'text': (Attributes map) => map
        ..putIfAbsent(
          'delta',
          () => Delta().toJson(),
        ),
    };
    return adapter[ty]?.call(map) ?? map;
  }
}

extension NodeToBlock on Node {
  BlockPB toBlock() {
    assert(id.isNotEmpty);
    final block = BlockPB.create()
      ..id = id
      ..ty = _typeAdapter(type)
      ..data = _dataAdapter(type, attributes);
    return block;
  }

  String _typeAdapter(String type) {
    final adapter = {
      'document': 'page',
      'paragraph': 'text',
    };
    return adapter[type] ?? type;
  }

  String _dataAdapter(String type, Attributes attributes) {
    return jsonEncode(attributes);
  }
}
