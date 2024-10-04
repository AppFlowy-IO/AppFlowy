import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { getText } from '@/application/slate-yjs/utils/yjsOperations';
import { calculateOffsetRelativeToParent } from '@/application/slate-yjs/utils/positions';
import { YjsEditorKey, YSharedRoot } from '@/application/types';
import {
  Operation,
  Element,
  Editor,
  InsertTextOperation,
  RemoveTextOperation,
  Descendant,
  SetNodeOperation, Path,
} from 'slate';
import * as Y from 'yjs';

// transform slate op to yjs op and apply it to ydoc
export function applyToYjs (ydoc: Y.Doc, editor: Editor, op: Operation, slateContent: Descendant[]) {
  if (op.type === 'set_selection') return;
  console.log('applySlateOp', op, slateContent);

  switch (op.type) {
    case 'insert_text':
      return applyInsertText(ydoc, editor, op, slateContent);
    case 'remove_text':
      return applyRemoveText(ydoc, editor, op, slateContent);
    case 'set_node':
      return applySetNode(ydoc, editor, op, slateContent);
    default:
      return;
  }
}

function applyInsertText (ydoc: Y.Doc, editor: Editor, op: InsertTextOperation, _slateContent: Descendant[]) {
  const { path, offset, text } = op;
  const node = findSlateNode(editor, path);
  const textId = node.textId as string;
  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const yText = getText(textId, sharedRoot);
  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  yText.insert(relativeOffset, text);
}

function getNodeAtPath (children: Descendant[], path: Path): Descendant | null {
  let currentNode: Descendant | null = null;
  let currentChildren = children;

  for (let i = 0; i < path.length; i++) {
    const index = path[i];

    if (index >= currentChildren.length) {
      return null;
    }

    currentNode = currentChildren[index];
    if (i === path.length - 1) {
      return currentNode;
    }

    if (!Element.isElement(currentNode) || !currentNode.children) {
      return null;
    }

    currentChildren = currentNode.children;
  }

  return currentNode;
}

function applyRemoveText (ydoc: Y.Doc, editor: Editor, op: RemoveTextOperation, slateContent: Descendant[]) {
  const { path, offset, text } = op;

  const node = getNodeAtPath(slateContent, path.slice(0, -1)) as Element;

  const textId = node.textId;

  if (!textId) return;

  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const yText = getText(textId, sharedRoot);
  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  yText.delete(relativeOffset, text.length);
}

function findSlateNode (editor: Editor, path: number[]): Element {
  const entry = CustomEditor.findTextNode(editor, path);

  return entry[0];
}

function applySetNode (ydoc: Y.Doc, editor: Editor, op: SetNodeOperation, slateContent: Descendant[]) {
  const { newProperties, path } = op;
  const leafKeys = Object.values(EditorMarkFormat) as string[];
  const properties = Object.keys(newProperties);

  const isLeaf = properties.some((prop: string) => leafKeys.includes(prop));

  if (!isLeaf) {
    console.log('set_node', newProperties);
    return;
  }

  const node = getNodeAtPath(slateContent, path.slice(0, -1)) as Element;
  const textId = node.textId;

  if (!textId) return;

  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const yText = getText(textId, sharedRoot);
  const [start, end] = Editor.edges(editor, path);

  const startRelativeOffset = Math.min(calculateOffsetRelativeToParent(node, start), yText.toJSON().length);
  const endRelativeOffset = Math.min(calculateOffsetRelativeToParent(node, end), yText.toJSON().length);

  const length = endRelativeOffset - startRelativeOffset;

  yText.format(startRelativeOffset, length, newProperties);

}