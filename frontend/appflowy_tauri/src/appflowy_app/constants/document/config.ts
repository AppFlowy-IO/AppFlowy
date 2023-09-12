import { Align, BlockConfig, BlockType, SplitRelationship } from '$app/interfaces/document';
import { randomEmoji } from '$app/utils/document/emoji';

/**
 * If the block type is not in the config, it will be thrown an error in development env
 */
export const blockConfig: Record<string, BlockConfig> = {
  [BlockType.TextBlock]: {
    canAddChild: true,
    defaultData: {},
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
      icon: randomEmoji(),
    },
    splitProps: {
      nextLineRelationShip: SplitRelationship.NextSibling,
      nextLineBlockType: BlockType.TextBlock,
    },
  },
  [BlockType.ToggleListBlock]: {
    canAddChild: true,
    defaultData: {
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
  [BlockType.ImageBlock]: {
    canAddChild: false,
    defaultData: {
      url: '',
      align: Align.Center,
      width: 0,
      height: 0,
      caption: [],
    },
  },
};
