import { YBlocks, YChildrenMap, YjsEditorKey, YMeta, YSharedRoot, YTextMap } from '@/application/types';

export function getText (textId: string, sharedRoot: YSharedRoot) {

  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const textMap = meta.get(YjsEditorKey.text_map) as YTextMap;

  return textMap.get(textId);
}

export function getChildBlockIds (blockId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const meta = document.get(YjsEditorKey.meta) as YMeta;
  const childrenMap = meta.get(YjsEditorKey.children_map) as YChildrenMap;

  return childrenMap.get(blockId);
}

export function getDocument (sharedRoot: YSharedRoot) {
  return sharedRoot.get(YjsEditorKey.document);
}

export function getBlock (blockId: string, sharedRoot: YSharedRoot) {
  const document = sharedRoot.get(YjsEditorKey.document);
  const blocks = document.get(YjsEditorKey.blocks) as YBlocks;

  return blocks.get(blockId);
}