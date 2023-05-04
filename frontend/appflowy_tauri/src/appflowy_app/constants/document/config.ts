import { BlockData, BlockType } from '$app/interfaces/document';

export enum SplitRelationship {
  NextSibling,
  FirstChild,
}
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
     * The regexps that will be used to match the markdown flag
     */
    markdownRegexps?: RegExp[];

    /**
     * The default data of the block
     */
    defaultData?: BlockData<any>;

    /**
     * The props that will be passed to the text split function
     */
    splitProps?: {
      /**
       * The relationship between the next line block and the current block
       */
      nextLineRelationShip: SplitRelationship;
      /**
       * The type of the next line block
       */
      nextLineBlockType: BlockType;
    };
  }
> = {
  [BlockType.TextBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TextBlock,
    },
  },
  [BlockType.HeadingBlock]: {
    canAddChild: false,
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TextBlock,
    },
    /**
     * # or ## or ###
     */
    markdownRegexps: [/^(#{1,3})(\s)+$/],
  },
  [BlockType.TodoListBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      checked: false,
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TodoListBlock,
    },
    /**
     * -[] or -[x] or -[ ] or [] or [x] or [ ]
     */
    markdownRegexps: [/^((-)?\[(x|\s)?\])(\s)+$/],
  },
  [BlockType.BulletedListBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      format: 'default',
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.BulletedListBlock,
    },
    /**
     * - or + or *
     */
    markdownRegexps: [/^(\s*[-+*])(\s)+$/],
  },
  [BlockType.NumberedListBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      format: 'default',
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.NumberedListBlock,
    },
    /**
     * 1. or 2. or 3.
     * a. or b. or c.
     */
    markdownRegexps: [/^(\s*[\d|a-zA-Z]+\.)(\s)+$/],
  },
  [BlockType.QuoteBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      size: 'default',
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TextBlock,
    },
    /**
     * " or “ or ”
     */
    markdownRegexps: [/^("|“|”)(\s)+$/],
  },
  [BlockType.ToggleListBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      collapsed: false,
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.FirstChild,
      nextLineBlockType: BlockType.TextBlock,
    },
    /**
     * >
     */
    markdownRegexps: [/^(>)(\s)+$/],
  },
  [BlockType.DividerBlock]: {
    canAddChild: false,
    /**
     * ---
     */
    markdownRegexps: [/^(-{3,})$/],
  },
  [BlockType.CodeBlock]: {
    canAddChild: false,
    /**
     * ```
     */
    markdownRegexps: [/^(```)$/],
  },
};
