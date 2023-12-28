import { Path, Element, NodeEntry } from 'slate';
import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command/index';

export const LIST_TYPES = [
  EditorNodeType.NumberedListBlock,
  EditorNodeType.BulletedListBlock,
  EditorNodeType.TodoListBlock,
  EditorNodeType.ToggleListBlock,
  EditorNodeType.QuoteBlock,
  EditorNodeType.Paragraph,
];

const LIST_ITEM_TYPES = [
  EditorNodeType.NumberedListBlock,
  EditorNodeType.BulletedListBlock,
  EditorNodeType.TodoListBlock,
  EditorNodeType.ToggleListBlock,
  EditorNodeType.QuoteBlock,
  EditorNodeType.Paragraph,
  EditorNodeType.HeadingBlock,
];

/**
 * Indent the current list item
 * Conditions:
 * 1. The current node must be a list item
 * 2. The previous node must be a list
 * 3. The previous node must be the same level as the current node
 * Result:
 * 1. The current node will be the child of the previous node
 * 2. The current node will be indented
 * 3. The children of the current node will be moved to the children of the previous node
 * @param editor
 */
export function tabForward(editor: ReactEditor) {
  const match = CustomEditor.getBlock(editor);

  if (!match) return;

  const [node, path] = match as NodeEntry<Element>;

  // the node is not a list item
  if (!LIST_ITEM_TYPES.includes(node.type as EditorNodeType)) {
    return;
  }

  const previousPath = Path.previous(path);

  const previous = editor.node(previousPath);
  const [previousNode] = previous as NodeEntry<Element>;

  if (!previousNode) return;

  const type = previousNode.type as EditorNodeType;

  // the previous node is not a list
  if (!LIST_TYPES.includes(type)) return;

  const toPath = [...previousPath, previousNode.children.length];

  editor.moveNodes({
    at: path,
    to: toPath,
  });

  node.children.forEach((child, index) => {
    if (index === 0) return;

    editor.liftNodes({
      at: [...toPath, index],
    });
  });
}

export function tabBackward(editor: ReactEditor) {
  const match = CustomEditor.getBlock(editor);

  if (!match) return;

  const [node, path] = match as NodeEntry<Element & { level: number }>;

  if (node.type === EditorNodeType.Page) return;
  if (node.type !== EditorNodeType.Paragraph) {
    CustomEditor.turnToBlock(editor, {
      type: EditorNodeType.Paragraph,
    });
    return;
  }

  editor.liftNodes({
    at: path,
  });
}
