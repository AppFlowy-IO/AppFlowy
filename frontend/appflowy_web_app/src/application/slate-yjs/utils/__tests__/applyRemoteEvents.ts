import {
  CollabOrigin,
  YBlocks,
  YChildrenMap,
  YjsEditorKey,
  YMeta,
  YSharedRoot,
  YTextMap,
} from '@/application/collab.type';
import { yDocToSlateContent } from '@/application/slate-yjs/utils/convert';
import { generateId, withTestingYDoc, withTestingYjsEditor } from './withTestingYjsEditor';
import { createEditor } from 'slate';
import { expect } from '@jest/globals';
import * as Y from 'yjs';

export async function runApplyRemoteEventsTest() {
  const pageId = generateId();
  const remoteDoc = withTestingYDoc(pageId);
  const remote = withTestingYjsEditor(createEditor(), remoteDoc);

  const localDoc = new Y.Doc();

  Y.applyUpdateV2(localDoc, Y.encodeStateAsUpdateV2(remoteDoc));
  const editor = withTestingYjsEditor(createEditor(), localDoc);

  editor.connect();
  expect(editor.children).toEqual(remote.children);

  // update remote doc
  insertBlock(remoteDoc, generateId(), pageId, 0);
  remote.children = yDocToSlateContent(remoteDoc)?.children ?? [];

  // apply remote changes to local doc
  Y.transact(
    localDoc,
    () => {
      Y.applyUpdateV2(localDoc, Y.encodeStateAsUpdateV2(remoteDoc));
    },
    CollabOrigin.Remote
  );

  expect(editor.children).toEqual(remote.children);
}

function insertBlock(doc: Y.Doc, blockId: string, parentId: string, index: number) {
  const sharedRoot = doc.getMap(YjsEditorKey.data_section) as YSharedRoot;
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  const block = new Y.Map();

  block.set(YjsEditorKey.block_id, blockId);
  block.set(YjsEditorKey.block_children, blockId);
  block.set(YjsEditorKey.block_type, 'paragraph');
  block.set(YjsEditorKey.block_data, '{}');
  block.set(YjsEditorKey.block_external_id, blockId);
  blocks.set(blockId, block);
  childrenMap.set(blockId, new Y.Array());
  childrenMap.get(parentId).insert(index, [blockId]);
  const text = new Y.Text();

  text.insert(0, 'Hello, World!');
  textMap.set(blockId, text);
}
