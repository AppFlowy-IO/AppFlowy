import { BlockType } from '$app/interfaces/document';

/**
 * Block types that are allowed to have children
 */
export const allowedChildrenBlockTypes = [BlockType.TextBlock, BlockType.PageBlock];
