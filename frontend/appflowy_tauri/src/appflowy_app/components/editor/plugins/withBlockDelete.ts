import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry, Path, Range } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

/**
 * Delete backward.
 * | -> cursor
 *
 * -------------------  delete backward to its previous sibling lift all children
 * 1                            1|2
 * |2                           3
 *    3  => delete backward =>  4
 *  4                           5
 * 5
 * ------------------- delete backward to its parent and lift all children
 * 1                            1|2
 *  |2                             3
 *   3  => delete backward =>      4
 *   4                          5
 * 5
 * ------------------- outdent the node if the node has no children
 * 1                            1
 *   2                            2
 *   |3                         |3
 * 4  => delete backward =>     4
 * @param editor
 */
export function withBlockDelete(editor: ReactEditor) {
  const { deleteBackward, deleteFragment, mergeNodes } = editor;

  editor.deleteBackward = (unit) => {
    const match = CustomEditor.getBlock(editor);

    if (!match || !CustomEditor.focusAtStartOfBlock(editor)) {
      deleteBackward(unit);
      return;
    }

    const [node, path] = match;

    const isEmbed = editor.isEmbed(node);

    if (isEmbed) {
      CustomEditor.deleteNode(editor, node);
      return;
    }

    const previous = editor.previous({
      at: path,
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
    });
    const [previousNode] = previous || [undefined, undefined];

    const previousIsPage = previousNode && Element.isElement(previousNode) && previousNode.type === EditorNodeType.Page;

    // merge to document title
    if (previousIsPage) {
      const textNodePath = [...path, 0];
      const [textNode] = editor.node(textNodePath);
      const text = CustomEditor.getNodeTextContent(textNode);

      // clear all attributes
      editor.select(textNodePath);
      CustomEditor.removeMarks(editor);
      editor.insertText(text);

      editor.move({
        distance: text.length,
        reverse: true,
      });
    }

    // if the current node is not a paragraph, convert it to a paragraph(except code block and callout block)
    if (
      ![EditorNodeType.Paragraph, EditorNodeType.CalloutBlock, EditorNodeType.CodeBlock].includes(
        node.type as EditorNodeType
      ) &&
      node.type !== EditorNodeType.Page
    ) {
      CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
      return;
    }

    const next = editor.next({
      at: path,
    });

    if (!next && path.length > 1) {
      CustomEditor.tabBackward(editor);
      return;
    }

    const length = node.children.length;

    for (let i = length - 1; i > 0; i--) {
      editor.liftNodes({
        at: [...path, i],
      });
    }

    // if previous node is an embed, merge the current node to another node which is not an embed
    if (Element.isElement(previousNode) && editor.isEmbed(previousNode)) {
      const previousTextMatch = editor.previous({
        at: path,
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.textId !== undefined,
      });

      if (!previousTextMatch) {
        deleteBackward(unit);
        return;
      }

      const previousTextPath = previousTextMatch[1];
      const textNode = node.children[0] as Element;

      const at = Editor.end(editor, previousTextPath);

      editor.select(at);
      editor.insertNodes(textNode.children, {
        at,
      });

      editor.removeNodes({
        at: path,
      });
      return;
    }

    deleteBackward(unit);
  };

  editor.deleteFragment = (...args) => {
    beforeDeleteToDocumentTitle(editor);

    deleteFragment(...args);
  };

  editor.mergeNodes = (options) => {
    mergeNodes(options);
    if (!editor.selection || !options?.at) return;
    const nextPath = findNextPath(editor, editor.selection.anchor.path);

    const [nextNode] = editor.node(nextPath);

    if (Element.isElement(nextNode) && nextNode.blockId !== undefined && nextNode.children.length === 0) {
      editor.removeNodes({
        at: nextPath,
      });
    }

    return;
  };

  return editor;
}

function beforeDeleteToDocumentTitle(editor: ReactEditor) {
  if (!editor.selection) return;
  if (Range.isCollapsed(editor.selection)) return;
  const start = Range.start(editor.selection);
  const end = Range.end(editor.selection);
  const startNode = editor.above({
    at: start,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.type === EditorNodeType.Page,
  });

  const endNode = editor.above({
    at: end,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
  });

  const startNodeIsPage = !!startNode;

  if (!startNodeIsPage || !endNode) return;
  const [node, path] = endNode as NodeEntry<Element>;
  const selectedText = editor.string({
    anchor: {
      path,
      offset: 0,
    },
    focus: end,
  });

  const nodeChildren = node.children;
  const nodeChildrenLength = nodeChildren.length;

  for (let i = nodeChildrenLength - 1; i > 0; i--) {
    editor.liftNodes({
      at: [...path, i],
    });
  }

  const textNodePath = [...path, 0];
  const [textNode] = editor.node(textNodePath);
  const text = CustomEditor.getNodeTextContent(textNode);

  // clear all attributes
  editor.select([...path, 0]);
  CustomEditor.removeMarks(editor);
  editor.insertText(text);
  editor.move({
    distance: text.length - selectedText.length,
    reverse: true,
  });
  editor.select({
    anchor: start,
    focus: editor.selection.focus,
  });
}

function findNextPath(editor: ReactEditor, path: Path): Path {
  if (path.length === 0) return path;
  const parentPath = Path.parent(path);

  try {
    const nextPath = Path.next(path);
    const [nextNode] = Editor.node(editor, nextPath);

    if (Element.isElement(nextNode) && nextNode.blockId !== undefined) {
      return nextPath;
    }
  } catch (e) {
    // ignore
  }

  return findNextPath(editor, parentPath);
}
