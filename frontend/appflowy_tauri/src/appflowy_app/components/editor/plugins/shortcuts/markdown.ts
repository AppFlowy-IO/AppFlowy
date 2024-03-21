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

export function isTriggerChar(char: string) {
  return Object.values(defaultTriggerChar).some((trigger) => trigger.includes(char));
}

export function whatShortcutTrigger(char: string): MarkdownShortcuts[] | null {
  const isTrigger = isTriggerChar(char);

  if (!isTrigger) {
    return null;
  }

  const shortcuts = Object.keys(defaultTriggerChar).map((key) => Number(key) as MarkdownShortcuts);

  return shortcuts.filter((shortcut) => defaultTriggerChar[shortcut].includes(char));
}

export function getRegex(shortcut: MarkdownShortcuts) {
  return defaultMarkdownRegex[shortcut];
}

export function whatShortcutsMatch(text: string) {
  const shortcuts = Object.keys(defaultMarkdownRegex).map((key) => Number(key) as MarkdownShortcuts);

  return shortcuts.filter((shortcut) => {
    const regexes = defaultMarkdownRegex[shortcut];

    return regexes.some((regex) => regex.pattern.test(text));
  });
}
