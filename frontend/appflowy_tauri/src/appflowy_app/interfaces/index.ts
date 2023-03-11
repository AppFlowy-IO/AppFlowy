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



export type BlockData<T> = T extends BlockType.TextBlock ? TextBlockData :
T extends BlockType.PageBlock ? PageBlockData :
T extends BlockType.HeadingBlock ? HeadingBlockData : 
T extends BlockType.ListBlock ? ListBlockData :
T extends BlockType.ColumnBlock ? ColumnBlockData :  any;


export interface Block<T = BlockType> {
  id: string;
  type: BlockType;
  data: BlockData<T>;
  next: string | null;
  firstChild: string | null;
}


interface TextBlockData {
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


export interface TreeNodeImp {
  id: string;
  type: BlockType;
  parent: TreeNodeImp | null;
  children: TreeNodeImp[];
  data: BlockData<BlockType>;
}