import {
  BlockType,
  YBlock,
  YBlocks,
  YChildrenMap,
  YjsEditorKey,
  YMeta,
  YSharedRoot,
  YTextMap,
} from '@/application/types';
import { nanoid } from 'nanoid';
import * as Y from 'yjs';

export function getText (textId: string, sharedRoot: YSharedRoot) {

  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  return textMap.get(textId);
}

export function getChildrenArray (childrenId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;

  return childrenMap.get(childrenId);
}

export function getDocument (sharedRoot: YSharedRoot) {
  return sharedRoot.get(YjsEditorKey.document);
}

export function getBlock (blockId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  return blocks.get(blockId);
}

export function generateBlockId () {
  return nanoid(8);
}

export function createBlock (sharedRoot: YSharedRoot, {
  ty,
  data,
}: {
  ty: BlockType;
  data: object;
}): YBlock {
  const block = new Y.Map();
  const id = generateBlockId();

  block.set(YjsEditorKey.block_id, id);
  block.set(YjsEditorKey.block_type, ty);
  block.set(YjsEditorKey.block_children, id);
  block.set(YjsEditorKey.block_external_id, id);
  block.set(YjsEditorKey.block_external_type, 'text');
  block.set(YjsEditorKey.block_data, JSON.stringify(data));

  const document = getDocument(sharedRoot);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  blocks.set(id, block);

  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  childrenMap.set(id, new Y.Array());
  textMap.set(id, new Y.Text());

  return block as YBlock;
}

export function updateBlockParent (sharedRoot: YSharedRoot, block: YBlock, parent: YBlock, index: number) {
  block.set(YjsEditorKey.block_parent, parent.get(YjsEditorKey.block_id));
  const parentChildren = getChildrenArray(parent.get(YjsEditorKey.block_children), sharedRoot);

  parentChildren.insert(index, [block.get(YjsEditorKey.block_id)]);
}