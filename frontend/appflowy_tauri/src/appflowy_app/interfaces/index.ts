import { Descendant } from "slate";

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

export type BlockData<T = BlockType> = T extends BlockType.TextBlock ? TextBlockData :
T extends BlockType.PageBlock ? PageBlockData :
T extends BlockType.HeadingBlock ? HeadingBlockData : 
T extends BlockType.ListBlock ? ListBlockData :
T extends BlockType.ColumnBlock ? ColumnBlockData :  any;


export interface BlockInterface<T = BlockType> {
  id: string;
  type: BlockType;
  data: BlockData<T>;
  next: string | null;
  firstChild: string | null;
}


export interface TextBlockData {
  content: Descendant[];
}

interface PageBlockData {
  title: string;
}

interface ListBlockData extends TextBlockData {
  type: 'numbered' | 'bulleted' | 'column';
}

interface HeadingBlockData extends TextBlockData {
  level: number;
}

interface ColumnBlockData {
  ratio: string;
}

// eslint-disable-next-line no-shadow
export enum TextBlockToolbarGroup {
  ASK_AI,
  BLOCK_SELECT,
  ADD_LINK,
  COMMENT,
  TEXT_FORMAT,
  TEXT_COLOR,
  MENTION,
  MORE
}
export interface TextBlockToolbarProps {
  showGroups: TextBlockToolbarGroup[]
}


export interface BlockCommonProps<T> {
  version: number;
  node: T;
}

export interface BackendOp {
  type: 'update' | 'insert' | 'remove' | 'move' | 'move_range';
  version: number;
  data: UpdateOpData | InsertOpData | moveRangeOpData | moveOpData | removeOpData;
}
export interface LocalOp {
  type: 'update' | 'insert' | 'remove' | 'move' | 'move_range';
  version: number;
  data: UpdateOpData | InsertOpData | moveRangeOpData | moveOpData | removeOpData;
}

export interface UpdateOpData {
  blockId: string;
  value: BlockData;
  path: string[];
}
export interface InsertOpData {
  block: BlockInterface;
  parentId: string;
  prevId?: string
}

export interface moveRangeOpData {
  range: [string, string];
  newParentId: string;
  newPrevId?: string
}

export interface moveOpData {
  blockId: string;
  newParentId: string;
  newPrevId?: string
}

export interface removeOpData {
  blockId: string
}