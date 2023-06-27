import { BlockConfig, BlockType, SplitRelationship } from '$app/interfaces/document';

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
  },

  [BlockType.CodeBlock]: {
    canAddChild: false,
    defaultData: {
      delta: [],
      language: 'javascript',
    },
  },
  [BlockType.DividerBlock]: {
    canAddChild: false,
  },
  [BlockType.EquationBlock]: {
    canAddChild: false,
    defaultData: {
      formula: '',
    },
  },
};
