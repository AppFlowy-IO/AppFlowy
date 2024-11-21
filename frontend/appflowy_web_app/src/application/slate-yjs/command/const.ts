import { BlockType } from '@/application/types';

/** List block types */
export const ListBlockTypes = [BlockType.TodoListBlock, BlockType.BulletedListBlock, BlockType.NumberedListBlock];

export const TOGGLE_BLOCK_TYPES = [BlockType.ToggleListBlock, BlockType.QuoteBlock, BlockType.CalloutBlock];

/** Container block types */
export const CONTAINER_BLOCK_TYPES = [
  BlockType.ToggleListBlock,
  BlockType.TodoListBlock,
  BlockType.Paragraph,
  BlockType.QuoteBlock,
  BlockType.BulletedListBlock,
  BlockType.NumberedListBlock,
  BlockType.Page,
  BlockType.CalloutBlock,
];
export const SOFT_BREAK_TYPES = [BlockType.CodeBlock];

export const isEmbedBlockTypes = (type: BlockType) => {
  return ![...ListBlockTypes, ...CONTAINER_BLOCK_TYPES, ...SOFT_BREAK_TYPES, BlockType.HeadingBlock].includes(type);
};