
// eslint-disable-next-line no-shadow
export enum BlockType {
  PageBlock = 0,
  HeadingBlock = 1,
  ListBlock = 2,
  TextBlock = 3,
  CodeBlock = 4,
  EmbedBlock = 5,
  QuoteBlock = 6,
  DividerBlock = 7,
  MediaBlock = 8,
  TableBlock = 9,
}



export type BlockData<T> = T extends BlockType.TextBlock ? TextBlockData :
T extends BlockType.PageBlock ? PageBlockData :
T extends BlockType.HeadingBlock ? HeadingBlockData: 
T extends BlockType.ListBlock ? ListBlockData : any;

export interface Block {
  id: string;
  type: BlockType;
  data: BlockData<BlockType>;
  parent: string | null;
  prev: string | null;
  next: string | null;
  firstChild: string | null;
  lastChild: string | null;
  children?: Block[];
}


interface TextBlockData {
  text: string;
  attr: string;
}

interface PageBlockData {
  title: string;
}

interface ListBlockData {
  type: 'ul' | 'ol';
}

interface HeadingBlockData {
  level: number;
}