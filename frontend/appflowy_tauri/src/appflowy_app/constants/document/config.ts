import { BlockType } from '$app/interfaces/document';

/**
 * Block types that are allowed to have children
 */
export const allowedChildrenBlockTypes = [
  BlockType.TextBlock,
  BlockType.PageBlock,
  BlockType.TodoListBlock,
  BlockType.QuoteBlock,
  BlockType.CalloutBlock,
];

/**
 * Block types that split node can extend to the next line
 */
export const splitableBlockTypes = [BlockType.TextBlock, BlockType.TodoListBlock];
