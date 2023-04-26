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

export type BlockData = TextBlockData | HeadingBlockData | PageBlockData;

export interface NestedBlock {
  id: string;
  type: BlockType;
  data: BlockData | Record<string, any>;
  parent: string | null;
  children: string;
}
export interface TextDelta {
  insert: string;
  attributes?: Record<string, string | boolean>;
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

export type Node = NestedBlock;

export interface SelectionPoint {
  path: [number, number];
  offset: number;
}

export interface TextSelection {
  anchor: SelectionPoint;
  focus: SelectionPoint;
}

export interface DocumentData {
  rootId: string;
  // map of block id to block
  nodes: Record<string, Node>;
  // map of block id to children block ids
  children: Record<string, string[]>;
}
export interface DocumentState {
  // map of block id to block
  nodes: Record<string, Node>;
  // map of block id to children block ids
  children: Record<string, string[]>;
  // selected block ids
  selections: string[];
  // map of block id to text selection
  textSelections: Record<string, TextSelection>;
}

// eslint-disable-next-line no-shadow
export enum ChangeType {
  BlockInsert,
  BlockUpdate,
  BlockDelete,
  ChildrenMapInsert,
  ChildrenMapUpdate,
  ChildrenMapDelete,
}

export interface BlockPBValue {
  id: string;
  ty: string;
  parent: string;
  children: string;
  data: string;
}
