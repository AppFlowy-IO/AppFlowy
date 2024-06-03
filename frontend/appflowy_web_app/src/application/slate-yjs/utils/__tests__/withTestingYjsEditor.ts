import { CollabOrigin, YjsEditorKey, YSharedRoot } from '@/application/collab.type';
import { withYjs } from '@/application/slate-yjs';
import { Editor } from 'slate';
import * as Y from 'yjs';
import { v4 as uuidv4 } from 'uuid';

export function generateId() {
  return uuidv4();
}

export function withTestingYjsEditor(editor: Editor, doc: Y.Doc) {
  const yjdEditor = withYjs(editor, doc, {
    localOrigin: CollabOrigin.LocalSync,
  });

  return yjdEditor;
}

export function withTestingYDoc(docId: string) {
  const doc = new Y.Doc();
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const document = new Y.Map();
  const blocks = new Y.Map();
  const meta = new Y.Map();
  const children_map = new Y.Map();
  const text_map = new Y.Map();
  const rootBlock = new Y.Map();
  const blockOrders = new Y.Array();
  const pageId = docId;

  sharedRoot.set(YjsEditorKey.document, document);
  document.set(YjsEditorKey.page_id, pageId);
  document.set(YjsEditorKey.blocks, blocks);
  document.set(YjsEditorKey.meta, meta);
  meta.set(YjsEditorKey.children_map, children_map);
  meta.set(YjsEditorKey.text_map, text_map);
  children_map.set(pageId, blockOrders);
  blocks.set(pageId, rootBlock);
  rootBlock.set(YjsEditorKey.block_id, pageId);
  rootBlock.set(YjsEditorKey.block_children, pageId);
  rootBlock.set(YjsEditorKey.block_type, 'page');
  rootBlock.set(YjsEditorKey.block_data, '{}');
  rootBlock.set(YjsEditorKey.block_external_id, '');
  return doc;
}
