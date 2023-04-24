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
  delta: TextDelta[];
}

export interface TextBlockData {
  delta: TextDelta[];
}

export type PageBlockData = TextBlockData;

export type BlockData = TextBlockData | HeadingBlockData | PageBlockData | Record<string, any>;

export interface NestedBlock {
  id: string;
  type: BlockType;
  data: BlockData;
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
  Move = 3,
}

export interface DeltaItem {
  action: 'inserted' | 'removed' | 'updated';
  payload: {
    id: string;
    value?: NestedBlock | string[];
  };
}
