import { Keyboard } from '$app/constants/document/keyboard';
import { BlockType } from '$app/interfaces/document';

export const turnIntoShortcuts = {
  [Keyboard.keys.SPACE]: [
    {
      type: BlockType.HeadingBlock,
      /**
       * # or ## or ###
       */
      markdownRegexp: /^(#{1,3})(\s)+$/,
    },
    {
      type: BlockType.TodoListBlock,
      /**
       * -[] or -[x] or -[ ] or [] or [x] or [ ]
       */
      markdownRegexp: /^((-)?\[(x|\s)?\])(\s)+$/,
    },
    {
      type: BlockType.BulletedListBlock,
      /**
       * - or + or *
       */
      markdownRegexp: /^(\s*[-+*])(\s)+$/,
    },
    {
      type: BlockType.NumberedListBlock,
      /**
       * 1. or 2. or 3.
       * a. or b. or c.
       */
      markdownRegexp: /^(\s*[\d|a-zA-Z]+\.)(\s)+$/,
    },
    {
      type: BlockType.QuoteBlock,
      /**
       * " or “ or ”
       */
      markdownRegexp: /^("|“|”)(\s)+$/,
    },
    {
      type: BlockType.CalloutBlock,
      /**
       * [!TIP] or [!INFO] or [!WARNING] or [!DANGER]
       */
      markdownRegexp: /^(\[!)(TIP|INFO|WARNING|DANGER)(\])(\s)+$/,
    },
    {
      type: BlockType.ToggleListBlock,
      /**
       * >
       */
      markdownRegexp: /^(>)(\s)+$/,
    },
  ],
  [Keyboard.keys.BACK_QUOTE]: [
    {
      type: BlockType.CodeBlock,
      /**
       * ```
       */
      markdownRegexp: /^(```)$/,
    },
  ],
  [Keyboard.keys.REDUCE]: [
    {
      type: BlockType.DividerBlock,
      /**
       * ---
       */
      markdownRegexp: /^(-{3,})$/,
    },
  ],
};
