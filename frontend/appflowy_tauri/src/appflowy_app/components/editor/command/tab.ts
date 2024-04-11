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

  const hasPrevious = Path.hasPrevious(path);

  if (!hasPrevious) return;

  const previousPath = Path.previous(path);

  const previous = editor.node(previousPath);
  const [previousNode] = previous as NodeEntry<Element>;

  if (!previousNode) return;

  const type = previousNode.type as EditorNodeType;

  if (type === EditorNodeType.Page) return;
  // the previous node is not a list
  if (!LIST_TYPES.includes(type)) return;

  const toPath = [...previousPath, previousNode.children.length];

  editor.moveNodes({
    at: path,
    to: toPath,
  });

  const length = node.children.length;

  for (let i = length - 1; i > 0; i--) {
    editor.liftNodes({
      at: [...toPath, i],
    });
  }
}

export function tabBackward(editor: ReactEditor) {
  const match = CustomEditor.getBlock(editor);

  if (!match) return;

  const [node, path] = match as NodeEntry<Element & { level: number }>;

  const depth = path.length;

  if (node.type === EditorNodeType.Page) return;

  if (depth === 1) return;
  editor.liftNodes({
    at: path,
  });
}
