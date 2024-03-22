import { EditorNodeType } from '$app/application/document/document.types';

export enum SlashCommandPanelTab {
  BASIC = 'basic',
  MEDIA = 'media',
  DATABASE = 'database',
  ADVANCED = 'advanced',
}

export enum SlashOptionType {
  Paragraph,
  TodoList,
  Heading1,
  Heading2,
  Heading3,
  BulletedList,
  NumberedList,
  Quote,
  ToggleList,
  Divider,
  Callout,
  Code,
  Grid,
  MathEquation,
  Image,
}

export const slashOptionGroup = [
  {
    key: SlashCommandPanelTab.BASIC,
    options: [
      SlashOptionType.Paragraph,
      SlashOptionType.TodoList,
      SlashOptionType.Heading1,
      SlashOptionType.Heading2,
      SlashOptionType.Heading3,
      SlashOptionType.BulletedList,
      SlashOptionType.NumberedList,
      SlashOptionType.Quote,
      SlashOptionType.ToggleList,
      SlashOptionType.Divider,
      SlashOptionType.Callout,
    ],
  },
  {
    key: SlashCommandPanelTab.MEDIA,
    options: [SlashOptionType.Code, SlashOptionType.Image],
  },
  {
    key: SlashCommandPanelTab.DATABASE,
    options: [SlashOptionType.Grid],
  },
  {
    key: SlashCommandPanelTab.ADVANCED,
    options: [SlashOptionType.MathEquation],
  },
];
export const slashOptionMapToEditorNodeType = {
  [SlashOptionType.Paragraph]: EditorNodeType.Paragraph,
  [SlashOptionType.TodoList]: EditorNodeType.TodoListBlock,
  [SlashOptionType.Heading1]: EditorNodeType.HeadingBlock,
  [SlashOptionType.Heading2]: EditorNodeType.HeadingBlock,
  [SlashOptionType.Heading3]: EditorNodeType.HeadingBlock,
  [SlashOptionType.BulletedList]: EditorNodeType.BulletedListBlock,
  [SlashOptionType.NumberedList]: EditorNodeType.NumberedListBlock,
  [SlashOptionType.Quote]: EditorNodeType.QuoteBlock,
  [SlashOptionType.ToggleList]: EditorNodeType.ToggleListBlock,
  [SlashOptionType.Divider]: EditorNodeType.DividerBlock,
  [SlashOptionType.Callout]: EditorNodeType.CalloutBlock,
  [SlashOptionType.Code]: EditorNodeType.CodeBlock,
  [SlashOptionType.Grid]: EditorNodeType.GridBlock,
  [SlashOptionType.MathEquation]: EditorNodeType.EquationBlock,
  [SlashOptionType.Image]: EditorNodeType.ImageBlock,
};
export const headingTypeToLevelMap: Record<string, number> = {
  [SlashOptionType.Heading1]: 1,
  [SlashOptionType.Heading2]: 2,
  [SlashOptionType.Heading3]: 3,
};
export const headingTypes = [SlashOptionType.Heading1, SlashOptionType.Heading2, SlashOptionType.Heading3];

export const SlashAliases = {
  [SlashOptionType.Paragraph]: ['paragraph', 'text', 'block', 'textblock'],
  [SlashOptionType.TodoList]: [
    'list',
    'todo',
    'todolist',
    'checkbox',
    'block',
    'todoblock',
    'checkboxblock',
    'todolistblock',
  ],
  [SlashOptionType.Heading1]: ['h1', 'heading1', 'block', 'headingblock', 'h1block'],
  [SlashOptionType.Heading2]: ['h2', 'heading2', 'block', 'headingblock', 'h2block'],
  [SlashOptionType.Heading3]: ['h3', 'heading3', 'block', 'headingblock', 'h3block'],
  [SlashOptionType.BulletedList]: [
    'list',
    'bulleted',
    'block',
    'bulletedlist',
    'bulletedblock',
    'listblock',
    'bulletedlistblock',
    'bulletelist',
  ],
  [SlashOptionType.NumberedList]: [
    'list',
    'numbered',
    'block',
    'numberedlist',
    'numberedblock',
    'listblock',
    'numberedlistblock',
    'numberlist',
  ],
  [SlashOptionType.Quote]: ['quote', 'block', 'quoteblock'],
  [SlashOptionType.ToggleList]: ['list', 'toggle', 'block', 'togglelist', 'toggleblock', 'listblock', 'togglelistblock'],
  [SlashOptionType.Divider]: ['divider', 'hr', 'block', 'dividerblock', 'line', 'lineblock'],
  [SlashOptionType.Callout]: ['callout', 'info', 'block', 'calloutblock'],
  [SlashOptionType.Code]: ['code', 'code', 'block', 'codeblock', 'media'],
  [SlashOptionType.Grid]: ['grid', 'table', 'block', 'gridblock', 'database'],
  [SlashOptionType.MathEquation]: [
    'math',
    'equation',
    'block',
    'mathblock',
    'mathequation',
    'mathequationblock',
    'advanced',
  ],
  [SlashOptionType.Image]: ['img', 'image', 'block', 'imageblock', 'media'],
};

export const reorderSlashOptions = (searchText: string) => {
  return (
    a: {
      key: SlashOptionType;
    },
    b: {
      key: SlashOptionType;
    }
  ) => {
    const compareIndex = (option: SlashOptionType) => {
      const aliases = SlashAliases[option];

      if (aliases) {
        for (const alias of aliases) {
          if (alias.startsWith(searchText)) {
            return -1;
          }
        }
      }

      return 0;
    };

    const compareLength = (option: SlashOptionType) => {
      const aliases = SlashAliases[option];

      if (aliases) {
        for (const alias of aliases) {
          if (alias.length < searchText.length) {
            return -1;
          }
        }
      }

      return 0;
    };

    return compareIndex(a.key) - compareIndex(b.key) || compareLength(a.key) - compareLength(b.key);
  };
};
