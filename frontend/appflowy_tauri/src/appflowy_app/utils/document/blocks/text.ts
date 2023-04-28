import { BlockType, NestedBlock, TextBlockData } from '$app/interfaces/document';
import { newBlock } from '$app/utils/document/blocks/common';

export function newTextBlock(parentId: string, data: TextBlockData): NestedBlock {
  return newBlock<BlockType.TextBlock>(BlockType.TextBlock, parentId, data);
}
