export type MarkdownRegex = {
  [key in MarkdownShortcuts]: {
    pattern: RegExp;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    data?: Record<string, any>;
  }[];
};

export type TriggerHotKey = {
  [key in MarkdownShortcuts]: string[];
};

export enum MarkdownShortcuts {
  Bold,
  Italic,
  StrikeThrough,
  Code,
  Equation,
  /** block */
  Heading,
  BlockQuote,
  CodeBlock,
  Divider,
  /** list */
  BulletedList,
  NumberedList,
  TodoList,
  ToggleList,
}

const defaultMarkdownRegex: MarkdownRegex = {
  [MarkdownShortcuts.Heading]: [
    {
      pattern: /^#{1,6}$/,
    },
  ],
  [MarkdownShortcuts.Bold]: [
    {
      pattern: /(\*\*|__)(.*?)(\*\*|__)$/,
    },
  ],
  [MarkdownShortcuts.Italic]: [
    {
      pattern: /([*_])(.*?)([*_])$/,
    },
  ],
  [MarkdownShortcuts.StrikeThrough]: [
    {
      pattern: /(~~)(.*?)(~~)$/,
    },
    {
      pattern: /(~)(.*?)(~)$/,
    },
  ],
  [MarkdownShortcuts.Code]: [
    {
      pattern: /(`)(.*?)(`)$/,
    },
  ],
  [MarkdownShortcuts.Equation]: [
    {
      pattern: /(\$)(.*?)(\$)$/,
      data: {
        formula: '',
      },
    },
  ],
  [MarkdownShortcuts.BlockQuote]: [
    {
      pattern: /^([”“"])$/,
    },
  ],
  [MarkdownShortcuts.CodeBlock]: [
    {
      pattern: /^(`{2,})$/,
      data: {
        language: 'json',
      },
    },
  ],
  [MarkdownShortcuts.Divider]: [
    {
      pattern: /^(([-*]){2,})$/,
    },
  ],

  [MarkdownShortcuts.BulletedList]: [
    {
      pattern: /^([*\-+])$/,
    },
  ],
  [MarkdownShortcuts.NumberedList]: [
    {
      pattern: /^(\d+)\.$/,
    },
  ],
  [MarkdownShortcuts.TodoList]: [
    {
      pattern: /^(-)?\[ ]$/,
      data: {
        checked: false,
      },
    },
    {
      pattern: /^(-)?\[x]$/,
      data: {
        checked: true,
      },
    },
    {
      pattern: /^(-)?\[]$/,
      data: {
        checked: false,
      },
    },
  ],
  [MarkdownShortcuts.ToggleList]: [
    {
      pattern: /^>$/,
      data: {
        collapsed: false,
      },
    },
  ],
};

export const defaultTriggerChar: TriggerHotKey = {
  [MarkdownShortcuts.Heading]: [' '],
  [MarkdownShortcuts.Bold]: ['*', '_'],
  [MarkdownShortcuts.Italic]: ['*', '_'],
  [MarkdownShortcuts.StrikeThrough]: ['~'],
  [MarkdownShortcuts.Code]: ['`'],
  [MarkdownShortcuts.BlockQuote]: [' '],
  [MarkdownShortcuts.CodeBlock]: ['`'],
  [MarkdownShortcuts.Divider]: ['-', '*'],
  [MarkdownShortcuts.Equation]: ['$'],
  [MarkdownShortcuts.BulletedList]: [' '],
  [MarkdownShortcuts.NumberedList]: [' '],
  [MarkdownShortcuts.TodoList]: [' '],
  [MarkdownShortcuts.ToggleList]: [' '],
};

