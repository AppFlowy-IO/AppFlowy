import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show Document, Node, Attributes, Delta, ParagraphBlockKeys, NodeIterator;
import 'package:collection/collection.dart';
import 'package:nanoid/nanoid.dart';

extension DocumentDataPBFromTo on DocumentDataPB {
  static DocumentDataPB? fromDocument(Document document) {
    final startNode = document.first;
    final endNode = document.last;
    if (startNode == null || endNode == null) {
      return null;
    }
    final pageId = document.root.id;

    // generate the block
    final blocks = <String, BlockPB>{};
    final nodes = NodeIterator(
      document: document,
      startNode: startNode,
      endNode: endNode,
    ).toList();
    for (final node in nodes) {
      if (blocks.containsKey(node.id)) {
        assert(false, 'duplicate node id: ${node.id}');
      }
      final parentId = node.parent?.id;
      final childrenId = nanoid(10);
      blocks[node.id] = node.toBlock(
        parentId: parentId,
        childrenId: childrenId,
      );
    }
    // root
    blocks[pageId] = document.root.toBlock(
      parentId: '',
      childrenId: pageId,
    );

    // generate the meta
    final childrenMap = <String, ChildrenPB>{};
    blocks.forEach((key, value) {
      final parentId = value.parentId;
      if (parentId.isNotEmpty) {
        childrenMap[parentId] ??= ChildrenPB.create();
        childrenMap[parentId]!.children.add(value.id);
      }
    });
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

extension BlockToNode on BlockPB {
  Node toNode({
    Iterable<Node>? children,
  }) {
    return Node(
      id: id,
      type: ty,
      attributes: _dataAdapter(ty, data),
      children: children ?? [],
    );
  }

  Attributes _dataAdapter(String ty, String data) {
    final map = Attributes.from(jsonDecode(data));
    final adapter = {
      ParagraphBlockKeys.type: (Attributes map) => map
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
    String? parentId,
    String? childrenId,
  }) {
    assert(id.isNotEmpty);
    final block = BlockPB.create()
      ..id = id
      ..ty = type
      ..data = _dataAdapter(type, attributes);
    if (childrenId != null && childrenId.isNotEmpty) {
      block.childrenId = childrenId;
    }
    if (parentId != null && parentId.isNotEmpty) {
      block.parentId = parentId;
    }
    return block;
  }

  String _dataAdapter(String type, Attributes attributes) {
    return jsonEncode(attributes);
  }
}
