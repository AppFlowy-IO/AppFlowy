import { BlockType } from '@/application/types';

/** List block types */
export const ListBlockTypes = [BlockType.TodoListBlock, BlockType.BulletedListBlock, BlockType.NumberedListBlock];

/** Container block types */
export const CONTAINER_BLOCK_TYPES = [
  BlockType.ToggleListBlock,
  BlockType.TodoListBlock,
  BlockType.Paragraph,
  BlockType.QuoteBlock,
  BlockType.BulletedListBlock,
  BlockType.NumberedListBlock,
  BlockType.Page,
];
export const SOFT_BREAK_TYPES = [BlockType.CalloutBlock, BlockType.CodeBlock];