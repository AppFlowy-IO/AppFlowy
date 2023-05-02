import { BlockType } from '$app/interfaces/document';

/**
 * If the block type is not in the config, it will be thrown an error in development env
 */
export const blockConfig: Record<
  string,
  {
    /**
     * Whether the block can have children
     */
    canAddChild: boolean;
    /**
     * the type of the block that will be split from the current block
     */
    splitType: BlockType;
    /**
     * The regexps that will be used to match the markdown flag
     */
    markdownRegexps?: RegExp[];
  }
> = {
  [BlockType.TextBlock]: {
    canAddChild: true,
    splitType: BlockType.TextBlock,
  },
  [BlockType.HeadingBlock]: {
    canAddChild: false,
    splitType: BlockType.TextBlock,
    /**
     * # or ## or ###
     */
    markdownRegexps: [/^(#{1,3})$/],
  },
  [BlockType.TodoListBlock]: {
    canAddChild: true,
    splitType: BlockType.TodoListBlock,
    /**
     * -[] or -[x] or -[ ] or [] or [x] or [ ]
     */
    markdownRegexps: [/^((-)?\[(x|\s)?\])$/],
  },
  [BlockType.BulletedListBlock]: {
    canAddChild: true,
    splitType: BlockType.BulletedListBlock,
    /**
     * - or + or *
     */
    markdownRegexps: [/^(\s*[-+*])$/],
  },
  [BlockType.NumberedListBlock]: {
    canAddChild: true,
    splitType: BlockType.NumberedListBlock,
    /**
     * 1. or 2. or 3.
     */
    markdownRegexps: [/^(\s*\d+\.)$/],
  },
  [BlockType.QuoteBlock]: {
    canAddChild: true,
    splitType: BlockType.TextBlock,
    /**
     * " or “ or ”
     */
    markdownRegexps: [/^("|“|”)$/],
  },
  [BlockType.CodeBlock]: {
    canAddChild: false,
    splitType: BlockType.TextBlock,
    /**
     * ```
     */
    markdownRegexps: [/^(```)$/],
  },
};
