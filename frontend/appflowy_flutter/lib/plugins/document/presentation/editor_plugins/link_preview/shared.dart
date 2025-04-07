import 'package:appflowy/plugins/document/presentation/editor_plugins/link_embed/link_embed_block_component.dart';
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
  String href,
) async {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) return;
  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null) return;
  final length = href.length;
  final index = selection.normalized.startIndex - length;
  final transaction = editorState.transaction;
  transaction.deleteText(node, index, length);
  await editorState.apply(transaction);
  transaction
    ..insertNodes(node.path, [linkPreviewNode(url: href), paragraphNode()])
    ..afterSelection = Selection.collapsed(
      Position(path: node.path.next),
    );
  return editorState.apply(transaction);
}

Future<void> replaceNodeUrl(EditorState editorState, Node node, String url) =>
    convertLinkBlockToOtherLinkBlock(editorState, node, node.type, url: url);

Future<void> convertLinkBlockToOtherLinkBlock(
  EditorState editorState,
  Node node,
  String toType, {
  String? url,
}) async {
  final nodeType = node.type;
  if (_isNotLinkType(nodeType) ||
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

const _linkTypeSet = {LinkPreviewBlockKeys.type, LinkEmbedBlockKeys.type};

bool _isNotLinkType(String type) => !_linkTypeSet.contains(type);