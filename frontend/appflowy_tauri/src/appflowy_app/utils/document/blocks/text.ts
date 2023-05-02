import { BlockType, NestedBlock, TextBlockData, TextDelta } from '$app/interfaces/document';
import { newBlock } from '$app/utils/document/blocks/common';
import * as Y from 'yjs';

export function newTextBlock(parentId: string, data: TextBlockData): NestedBlock {
  return newBlock<BlockType.TextBlock>(BlockType.TextBlock, parentId, data);
}

export function isSameDelta(referDelta: TextDelta[], delta: TextDelta[]) {
  const ydoc = new Y.Doc();
  const yText = ydoc.getText('1');
  const yTextRefer = ydoc.getText('2');
  yText.applyDelta(delta);
  yTextRefer.applyDelta(referDelta);
  return JSON.stringify(yText.toDelta()) === JSON.stringify(yTextRefer.toDelta());
}
