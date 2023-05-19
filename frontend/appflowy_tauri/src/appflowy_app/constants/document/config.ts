import { BlockConfig, BlockType, SplitRelationship, TextAction, TextActionMenuProps } from '$app/interfaces/document';

/**
 * If the block type is not in the config, it will be thrown an error in development env
 */
export const blockConfig: Record<string, BlockConfig> = {
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
  [BlockType.CalloutBlock]: {
    canAddChild: true,
    defaultData: {
      delta: [],
      icon: 'bulb',
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TextBlock,
    },
    /**
     * [!TIP] or [!INFO] or [!WARNING] or [!DANGER]
     */
    markdownRegexps: [/^(\[!)(TIP|INFO|WARNING|DANGER)(\])(\s)+$/],
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
    defaultData: {
      delta: [],
      language: 'javascript',
    },
    /**
     * ```
     */
    markdownRegexps: [/^(```)$/],

    textActionMenuProps: {
      excludeItems: [TextAction.Code],
    },
  },
};

export const defaultTextActionProps: TextActionMenuProps = {
  customItems: [
    TextAction.Turn,
    TextAction.Bold,
    TextAction.Italic,
    TextAction.Underline,
    TextAction.Strikethrough,
    TextAction.Code,
    TextAction.Equation,
  ],
  excludeItems: [],
};

export const multiLineTextActionProps: TextActionMenuProps = {
  customItems: [TextAction.Bold, TextAction.Italic, TextAction.Underline, TextAction.Strikethrough, TextAction.Code],
};

export const multiLineTextActionGroups = [
  [
    TextAction.Bold,
    TextAction.Italic,
    TextAction.Underline,
    TextAction.Strikethrough,
    TextAction.Code,
    TextAction.Equation,
  ],
];

export const textActionGroups = [
  [TextAction.Turn],
  [
    TextAction.Bold,
    TextAction.Italic,
    TextAction.Underline,
    TextAction.Strikethrough,
    TextAction.Code,
    TextAction.Equation,
  ],
];
