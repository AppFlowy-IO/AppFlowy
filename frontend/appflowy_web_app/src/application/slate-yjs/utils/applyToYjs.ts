import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { calculateOffsetRelativeToParent } from '@/application/slate-yjs/utils/positions';
import { getBlock, getNodeAtPath, getText } from '@/application/slate-yjs/utils/yjsOperations';
import { YjsEditorKey, YSharedRoot } from '@/application/types';
import {
  Descendant,
  Editor,
  Element, InsertNodeOperation,
  InsertTextOperation,
  Operation,
  RemoveTextOperation,
  SetNodeOperation,
  Text,
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
    case 'insert_node':
      return applyInsertNode(ydoc, editor, op, slateContent);
    default:
      return;
  }
}

function getAttributesAtOffset (ytext: Y.Text, offset: number): object | null {
  const delta = ytext.toDelta();
  let currentOffset = 0;

  for (const op of delta) {
    if ('insert' in op) {
      const length = op.insert.length;

      if (currentOffset <= offset && offset < currentOffset + length) {
        return op.attributes || null;
      }

      currentOffset += length;
    }
  }

  return null;
}

function insertText (ydoc: Y.Doc, editor: Editor, { path, offset, text, attributes }: InsertTextOperation & {
  attributes?: object;
}, slateContent: Descendant[]) {
  const node = getNodeAtPath(slateContent, path.slice(0, -1)) as Element;

  console.log('insertText', node, slateContent);
  const textId = node.textId as string;
  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const yText = getText(textId, sharedRoot);

  if (!yText) return;
  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  console.log('insertText', point, node);
  const beforeAttributes = getAttributesAtOffset(yText, relativeOffset - 1);

  console.log('beforeAttributes', relativeOffset, beforeAttributes);

  if (beforeAttributes && ('formula' in beforeAttributes || 'mention' in beforeAttributes)) {
    const newAttributes = {
      ...attributes,
    };

    if ('formula' in beforeAttributes) {
      Object.assign({
        formula: undefined,
      });
    }

    if ('mention' in beforeAttributes) {
      Object.assign({
        mention: undefined,
      });
    }

    yText.insert(relativeOffset, text, newAttributes);
  } else {
    yText.insert(relativeOffset, text, attributes);
  }

  console.log('insertText', attributes, yText.toDelta());

}

function applyInsertText (ydoc: Y.Doc, editor: Editor, op: InsertTextOperation, slateContent: Descendant[]) {
  const { path, offset, text } = op;

  insertText(ydoc, editor, { path, offset, text, type: 'insert_text' }, slateContent);
}

function applyInsertNode (ydoc: Y.Doc, editor: Editor, op: InsertNodeOperation, slateContent: Descendant[]) {
  const { path, node } = op;

  if (!Text.isText(node)) return;
  const text = node.text;
  const offset = 0;

  insertText(ydoc, editor, {
    path, offset, text, type: 'insert_text', attributes: {},
  }, slateContent);
}

function applyRemoveText (ydoc: Y.Doc, editor: Editor, op: RemoveTextOperation, slateContent: Descendant[]) {
  const { path, offset, text } = op;

  const node = getNodeAtPath(slateContent, path.slice(0, -1)) as Element;

  const textId = node.textId;

  if (!textId) return;

  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const yText = getText(textId, sharedRoot);

  if (!yText) return;

  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  yText.delete(relativeOffset, text.length);
}

function applySetNode (ydoc: Y.Doc, editor: Editor, op: SetNodeOperation, slateContent: Descendant[]) {
  const { newProperties, path } = op;
  const leafKeys = Object.values(EditorMarkFormat) as string[];
  const properties = Object.keys(newProperties);

  const isLeaf = properties.some((prop: string) => leafKeys.includes(prop));
  const isData = properties.some((prop: string) => prop === 'data');
  const sharedRoot = ydoc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  console.log('applySetNode isLeaf', isLeaf, op);
  if (isLeaf) {
    const node = getNodeAtPath(slateContent, path.slice(0, -1)) as Element;
    const textId = node.textId;

    if (!textId) return;

    const yText = getText(textId, sharedRoot);
    const [start, end] = Editor.edges(editor, path);

    const startRelativeOffset = Math.min(calculateOffsetRelativeToParent(node, start), yText.toJSON().length);
    const endRelativeOffset = Math.min(calculateOffsetRelativeToParent(node, end), yText.toJSON().length);

    const length = endRelativeOffset - startRelativeOffset;

    yText.format(startRelativeOffset, length, newProperties);
    return;
  }

  if (isData) {
    const node = getNodeAtPath(slateContent, path) as Element;
    const blockId = node.blockId as string;

    if (!blockId) {
      console.error('blockId is not found in node', node, newProperties);
      return;
    }

    const block = getBlock(blockId, sharedRoot);

    if (
      'data' in newProperties
    ) {
      block.set(YjsEditorKey.block_data, JSON.stringify(newProperties.data));
      return;
    }
  }

  console.error('set_node operation is not supported', op);
}