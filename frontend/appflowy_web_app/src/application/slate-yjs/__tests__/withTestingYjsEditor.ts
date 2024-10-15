import {
  CollabOrigin,
  YBlocks,
  YChildrenMap,
  YjsEditorKey,
  YMeta,
  YSharedRoot,
  YTextMap,
} from '@/application/types';
import { withYjs } from '@/application/slate-yjs';
import { YDelta } from '@/application/slate-yjs/utils/convert';
import { Editor } from 'slate';
import * as Y from 'yjs';
import { v4 as uuidv4 } from 'uuid';

export function generateId () {
  return uuidv4();
}

export function withTestingYjsEditor (editor: Editor, doc: Y.Doc) {
  const yjdEditor = withYjs(editor, doc, {
    localOrigin: CollabOrigin.Local,
    readOnly: true,
  });

  return yjdEditor;
}

export function getTestingDocData (doc: Y.Doc) {
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;
  const pageId = document.get(YjsEditorKey.page_id) as string;

  return {
    sharedRoot,
    document,
    blocks,
    meta,
    childrenMap,
    textMap,
    pageId,
  };
}

export function withTestingYDoc (docId: string) {
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

export interface BlockObject {
  id: string;
  ty: string;
  relation_id: string;
  text_id: string;
  data: string;
}

export function insertBlock ({
  doc,
  parentBlockId,
  prevBlockId,
  blockObject,
}: {
  doc: Y.Doc;
  parentBlockId?: string;
  prevBlockId?: string;
  blockObject: BlockObject;
}) {
  const { blocks, childrenMap, textMap, pageId } = getTestingDocData(doc);
  const block = new Y.Map();
  const { id, ty, relation_id, text_id, data } = blockObject;

  block.set(YjsEditorKey.block_id, id);
  block.set(YjsEditorKey.block_type, ty);
  block.set(YjsEditorKey.block_children, relation_id);
  block.set(YjsEditorKey.block_external_id, text_id);
  block.set(YjsEditorKey.block_data, data);
  blocks.set(id, block);

  const blockParentId = parentBlockId || pageId;
  const blockParentChildren = childrenMap.get(blockParentId);
  const index = prevBlockId ? blockParentChildren.toArray().indexOf(prevBlockId) + 1 : 0;

  blockParentChildren.insert(index, [id]);

  return {
    applyDelta: (delta: YDelta[]) => {
      let text = textMap.get(text_id);

      if (!text) {
        text = new Y.Text();
        textMap.set(text_id, text);
      }

      text.applyDelta(delta);
    },
    appendChild: (childBlock: BlockObject) => {
      if (!childrenMap.has(relation_id)) {
        childrenMap.set(relation_id, new Y.Array());
      }

      return insertBlock({
        doc,
        parentBlockId: id,
        blockObject: childBlock,
      });
    },
  };
}
