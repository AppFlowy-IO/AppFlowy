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
  ColumnBlock = 'column'
}
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
  ytexts: Record<string, TextDelta[]>;
  yarrays: Record<string, string[]>;
}
