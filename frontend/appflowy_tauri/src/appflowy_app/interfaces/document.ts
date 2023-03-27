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
  externalId: string;
  externalType: 'text' | 'array' | 'map';
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
    text_map: Record<string, TextDelta[]>;
    children_map: Record<string, string[]>;
  }
}
