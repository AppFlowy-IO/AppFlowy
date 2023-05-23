import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show Document, Node, Attributes, Delta, ParagraphBlockKeys;
import 'package:collection/collection.dart';

extension AppFlowyEditor on DocumentDataPB {
  DocumentDataPB? fromDocument(Document document) {
    final blocks = <String, BlockPB>{};
    final pageId = document.root.id;
    final childrenMap = <String, ChildrenPB>{};
    final meta = MetaPB(childrenMap: childrenMap);
    return DocumentDataPB(
      blocks: blocks,
      pageId: pageId,
      meta: meta,
    );
  }

  Document? toDocument() {
    final rootId = pageId;
    try {
      final root = buildNode(rootId);

      if (root != null) {
        return Document(root: root);
      }

      return null;
    } catch (e) {
      Log.error('create document error: $e');
      return null;
    }
  }

  Node? buildNode(String id) {
    final block = blocks[id];
    final childrenId = block?.childrenId;
    final childrenIds = meta.childrenMap[childrenId]?.children;

    final children = <Node>[];
    if (childrenIds != null && childrenIds.isNotEmpty) {
      children.addAll(childrenIds.map((e) => buildNode(e)).whereNotNull());
    }

    return block?.toNode(children: children);
  }
}

class _BackendKeys {
  const _BackendKeys._();

  static const String page = 'page';
  static const String text = 'text';
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
      _BackendKeys.page: 'document',
      _BackendKeys.text: ParagraphBlockKeys.type,
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
  BlockPB toBlock({
    String? childrenId,
  }) {
    assert(id.isNotEmpty);
    final block = BlockPB.create()
      ..id = id
      ..ty = _typeAdapter(type)
      ..data = _dataAdapter(type, attributes);
    if (childrenId != null && childrenId.isNotEmpty) {
      block.childrenId = childrenId;
    }
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
