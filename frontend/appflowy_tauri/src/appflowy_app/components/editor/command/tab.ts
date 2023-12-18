import { Editor, Element, NodeEntry, Transforms } from 'slate';
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
  const [match] = Editor.nodes(editor, {
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n),
  });

  if (!match) return;

  const [node, path] = match as NodeEntry<Element>;

  // the node is not a list item
  if (!LIST_ITEM_TYPES.includes(node.type as EditorNodeType)) {
    return;
  }

  const previous = Editor.previous(editor, {
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n) && n.level === node.level,
    at: path,
  });

  if (!previous) return;

  const [previousNode] = previous as NodeEntry<Element>;

  if (!previousNode) return;
  const type = previousNode.type as EditorNodeType;

  // the previous node is not a list
  if (!LIST_TYPES.includes(type)) return;

  const previousNodeLevel = previousNode.level;

  if (!previousNodeLevel) return;

  const newParentId = previousNode.blockId;
  const children = CustomEditor.findNodeChildren(editor, node);

  children.forEach((child) => {
    const childPath = ReactEditor.findPath(editor, child);

    Transforms.setNodes(
      editor,
      {
        parentId: newParentId,
      },
      {
        at: childPath,
      }
    );
  });

  const newProperties = { level: previousNodeLevel + 1, parentId: newParentId };

  Transforms.setNodes(editor, newProperties);
}

/**
 * Outdent the current list item
 * Conditions:
 * 1. The current node must be a list item
 * 2. The current node must be indented
 * Result:
 * 1. The current node will be the sibling of the parent node
 * 2. The current node will be outdented
 * 3. The children of the parent node will be moved to the children of the current node
 * @param editor
 */
export function tabBackward(editor: ReactEditor) {
  const [match] = Editor.nodes(editor, {
    match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n),
  });

  if (!match) return;

  const [node] = match as NodeEntry<Element & { level: number }>;

  const level = node.level;

  if (level === 1) return;
  const parent = CustomEditor.findParentNode(editor, node);

  if (!parent) return;

  const newParentId = parent.parentId;

  if (!newParentId) return;

  const newProperties = { level: level - 1, parentId: newParentId };

  const parentChildren = CustomEditor.findNodeChildren(editor, parent);

  const nodeIndex = parentChildren.findIndex((child) => child.blockId === node.blockId);

  Transforms.setNodes(editor, newProperties);

  for (let i = nodeIndex + 1; i < parentChildren.length; i++) {
    const child = parentChildren[i];
    const childPath = ReactEditor.findPath(editor, child);

    Transforms.setNodes(editor, { parentId: node.blockId }, { at: childPath });
  }
}
