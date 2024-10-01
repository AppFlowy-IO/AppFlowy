import { CustomEditor } from '@/application/slate-yjs/command';
import { calculateOffsetRelativeToParent } from '@/application/slate-yjs/utils/positions';
import { YjsEditorKey, YMeta, YSharedRoot, YTextMap } from '@/application/types';
import { Operation, Element, Editor, InsertTextOperation, RemoveTextOperation, Descendant } from 'slate';
import * as Y from 'yjs';

// transform slate op to yjs op and apply it to ydoc
export function applyToYjs (ydoc: Y.Doc, editor: Editor, op: Operation, slateContent: Descendant[]) {
  if (op.type === 'set_selection') return;
  console.log('applySlateOp', op);

  switch (op.type) {
    case 'insert_text':
      return applyInsertText(ydoc, editor, op, slateContent);
    case 'remove_text':
      return applyRemoveText(ydoc, editor, op, slateContent);
    default:
      return;
  }
}

function applyInsertText (ydoc: Y.Doc, editor: Editor, op: InsertTextOperation, _slateContent: Descendant[]) {
  const { path, offset, text } = op;
  const node = findSlateNode(editor, path);
  const textMap = getTextMap(ydoc);
  const textId = node.textId as string;
  const yText = textMap.get(textId);
  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  yText.insert(relativeOffset, text);
}

function applyRemoveText (ydoc: Y.Doc, editor: Editor, op: RemoveTextOperation, slateContent: Descendant[]) {
  const { path, offset, text } = op;
  const node = (slateContent[0] as Element)?.children?.[0] as Element;
  const textId = node.textId;

  if (!textId) return;

  const textMap = getTextMap(ydoc);
  const yText = textMap.get(textId);
  const point = { path, offset };

  const relativeOffset = Math.min(calculateOffsetRelativeToParent(node, point), yText.toJSON().length);

  yText.delete(relativeOffset, text.length);
}

function getTextMap (doc: Y.Doc) {
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;

  const document = sharedRoot.get(YjsEditorKey.document);

  const meta = document.get(YjsEditorKey.meta) as YMeta;

  return meta.get(YjsEditorKey.text_map) as YTextMap;
}

function findSlateNode (editor: Editor, path: number[]): Element {
  const entry = CustomEditor.findTextNode(editor, path);

  return entry[0];
}