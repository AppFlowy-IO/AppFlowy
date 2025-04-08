import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

Future<void> convertUrlPreviewNodeToLink(
  EditorState editorState,
  Node node,
) async {
  if (node.type != LinkPreviewBlockKeys.type) {
    return;
  }

  final url = node.attributes[LinkPreviewBlockKeys.url];
  final delta = Delta()
    ..insert(
      url,
      attributes: {
        AppFlowyRichTextKeys.href: url,
      },
    );
  final transaction = editorState.transaction;
  transaction
    ..insertNode(node.path, paragraphNode(delta: delta))
    ..deleteNode(node);
  transaction.afterSelection = Selection.collapsed(
    Position(
      path: node.path,
      offset: url.length,
    ),
  );
  return editorState.apply(transaction);
}

Future<void> removeUrlPreviewLink(
  EditorState editorState,
  Node node,
) async {
  if (node.type != LinkPreviewBlockKeys.type) {
    return;
  }

  final url = node.attributes[LinkPreviewBlockKeys.url];
  final delta = Delta()..insert(url);
  final transaction = editorState.transaction;
  transaction
    ..insertNode(node.path, paragraphNode(delta: delta))
    ..deleteNode(node);
  transaction.afterSelection = Selection.collapsed(
    Position(
      path: node.path,
      offset: url.length,
    ),
  );
  return editorState.apply(transaction);
}

Future<void> convertUrlToLinkPreview(
  EditorState editorState,
  Selection selection,
  String url, {
  String? previewType,
}) async {
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return;
  }
  final delta = node.delta;
  if (delta == null) return;
  final List<TextInsert> beforeOperations = [], afterOperations = [];
  int index = 0;
  for (final insert in delta.whereType<TextInsert>()) {
    if (index < selection.startIndex) {
      beforeOperations.add(insert);
    } else if (index >= selection.endIndex) {
      afterOperations.add(insert);
    }
    index += insert.length;
  }
  final transaction = editorState.transaction;
  transaction
    ..deleteNode(node)
    ..insertNodes(node.path.next, [
      if (beforeOperations.isNotEmpty)
        paragraphNode(delta: Delta(operations: beforeOperations)),
      if (previewType == LinkEmbedKeys.embed)
        linkEmbedNode(url: url)
      else
        linkPreviewNode(url: url),
      paragraphNode(delta: Delta(operations: afterOperations)),
    ]);
  await editorState.apply(transaction);
}

Future<void> convertUrlToMention(
  EditorState editorState,
  Selection selection,
) async {
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return;
  }
  final delta = node.delta;
  if (delta == null) return;
  String url = '';
  int index = 0;
  for (final insert in delta.whereType<TextInsert>()) {
    if (index >= selection.startIndex && index < selection.endIndex) {
      final href = insert.attributes?.href ?? '';
      if (href.isNotEmpty) {
        url = href;
        break;
      }
    }
    index += insert.length;
  }
  final transaction = editorState.transaction;
  transaction.replaceText(
    node,
    selection.startIndex,
    selection.length,
    MentionBlockKeys.mentionChar,
    attributes: {
      MentionBlockKeys.mention: {
        MentionBlockKeys.type: MentionType.externalLink.name,
        MentionBlockKeys.url: url,
      },
    },
  );
  await editorState.apply(transaction);
}

Future<void> convertLinkBlockToOtherLinkBlock(
  EditorState editorState,
  Node node,
  String toType, {
  String? url,
}) async {
  final nodeType = node.type;
  if (nodeType != LinkPreviewBlockKeys.type ||
      (nodeType == toType && url == null)) {
    return;
  }
  final insertedNode = <Node>[];

  final afterUrl = url ?? node.attributes[LinkPreviewBlockKeys.url] ?? '';
  Node afterNode = node.copyWith(
    type: toType,
    attributes: {
      LinkPreviewBlockKeys.url: afterUrl,
      blockComponentBackgroundColor:
          node.attributes[blockComponentBackgroundColor],
      blockComponentTextDirection: node.attributes[blockComponentTextDirection],
      blockComponentDelta: (node.delta ?? Delta()).toJson(),
    },
  );
  afterNode = afterNode.copyWith(children: []);
  insertedNode.add(afterNode);
  insertedNode.addAll(node.children.map((e) => e.deepCopy()));
  final transaction = editorState.transaction;
  transaction.insertNodes(
    node.path,
    insertedNode,
  );
  transaction.deleteNodes([node]);
  await editorState.apply(transaction);
}
