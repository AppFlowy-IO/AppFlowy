// eslint-disable-next-line no-shadow
export enum BlockType {
  PageBlock = 'page',
  HeadingBlock = 'heading',
  ListBlock = 'list',
  TextBlock = 'text',
  CodeBlock = 'code',
  EmbedBlock = 'embed',
  QuoteBlock = 'quote',
  DividerBlock = 'divider',
  MediaBlock = 'media',
  TableBlock = 'table',
  ColumnBlock = 'column',
}

export interface HeadingBlockData {
  level: number;
}

export interface TextBlockData {
  delta: TextDelta[];
}

export interface PageBlockData extends TextBlockData {}

export interface NestedBlock {
  id: string;
  type: BlockType;
  data: Record<string, any>;
  parent: string | null;
  children: string;
}
export interface TextDelta {
  insert: string;
  attributes?: Record<string, string | boolean>;
}
export interface DocumentData {
  rootId: string;
  blocks: Record<string, NestedBlock>;
  meta: {
    childrenMap: Record<string, string[]>;
  };
}

// eslint-disable-next-line no-shadow
export enum BlockActionType {
  Insert = 0,
  Update = 1,
  Delete = 2,
  Move = 3
}
