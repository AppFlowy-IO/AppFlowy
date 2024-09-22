import { CustomEditor } from '@/application/slate-yjs/command';
import { YjsEditorKey, YMeta, YSharedRoot, YTextMap } from '@/application/types';
import { Operation, Element, Editor, InsertTextOperation, RemoveTextOperation } from 'slate';
import * as Y from 'yjs';

// transform slate op to yjs op and apply it to ydoc
export function applyToYjs (ydoc: Y.Doc, editor: Editor, op: Operation) {
  if (op.type === 'set_selection') return;
  console.log('applySlateOp', op);

  switch (op.type) {
    case 'insert_text':
      return applyInsertText(ydoc, editor, op);
    case 'remove_text':
      return applyRemoveText(ydoc, editor, op);
    default:
      return;
  }
}

function applyInsertText (ydoc: Y.Doc, editor: Editor, op: InsertTextOperation) {
  const { path, offset, text } = op;
  const node = findSlateNode(editor, path);
  const textMap = getTextMap(ydoc);
  const textId = node.textId as string;
  const yText = textMap.get(textId);

  yText.insert(offset, text);
}

function applyRemoveText (ydoc: Y.Doc, editor: Editor, op: RemoveTextOperation) {
  const { path, offset, text } = op;
  const node = findSlateNode(editor, path);
  const textMap = getTextMap(ydoc);
  const textId = node.textId as string;
  const yText = textMap.get(textId);

  yText.delete(offset, text.length);
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