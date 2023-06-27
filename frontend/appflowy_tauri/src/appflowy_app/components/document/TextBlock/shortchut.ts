import { Keyboard } from '$app/constants/document/keyboard';
import { BlockType } from '$app/interfaces/document';

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
export const turnIntoConfig: Record<
  BlockType,
  {
    type: BlockType;
    markdownRegexp: RegExp;
    triggerKey: string;
  }
> = {
  [BlockType.HeadingBlock]: {
    type: BlockType.HeadingBlock,
    markdownRegexp: /^(#{1,3})(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.TodoListBlock]: {
    type: BlockType.TodoListBlock,
    markdownRegexp: /^((-)?\[(x|\s)?\])(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.BulletedListBlock]: {
    type: BlockType.BulletedListBlock,
    markdownRegexp: /^(\s*[-+*])(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.NumberedListBlock]: {
    type: BlockType.NumberedListBlock,
    markdownRegexp: /^(\s*[\d|a-zA-Z]+\.)(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.QuoteBlock]: {
    type: BlockType.QuoteBlock,
    markdownRegexp: /^("|“|”)(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.ToggleListBlock]: {
    type: BlockType.ToggleListBlock,
    markdownRegexp: /^(>)(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.CalloutBlock]: {
    type: BlockType.CalloutBlock,
    markdownRegexp: /^(\[!)(TIP|INFO|WARNING|DANGER)(\])(\s)+$/,
    triggerKey: Keyboard.keys.SPACE,
  },
  [BlockType.EquationBlock]: {
    type: BlockType.EquationBlock,
    markdownRegexp: /^(\${2})(\s)*(.+)(\s)*(\${2})$/,
    triggerKey: Keyboard.keys.DOLLAR,
  },
  [BlockType.DividerBlock]: {
    type: BlockType.DividerBlock,
    markdownRegexp: /^(-{3,})$/,
    triggerKey: Keyboard.keys.REDUCE,
  },
  [BlockType.CodeBlock]: {
    type: BlockType.CodeBlock,
    markdownRegexp: /^(```)$/,
    triggerKey: Keyboard.keys.BACK_QUOTE,
  },
};
