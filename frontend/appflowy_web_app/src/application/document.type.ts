import Y from 'yjs';

export type BlockId = string;

export type ExternalId = string;

export type ChildrenId = string;

export enum BlockType {
  Paragraph = 'paragraph',
  Page = 'page',
  HeadingBlock = 'heading',
  TodoListBlock = 'todo_list',
  BulletedListBlock = 'bulleted_list',
  NumberedListBlock = 'numbered_list',
  ToggleListBlock = 'toggle_list',
  CodeBlock = 'code',
  EquationBlock = 'math_equation',
  QuoteBlock = 'quote',
  CalloutBlock = 'callout',
  DividerBlock = 'divider',
  ImageBlock = 'image',
  GridBlock = 'grid',
  OutlineBlock = 'outline',
  TableBlock = 'table',
  TableCell = 'table/cell',
}

export enum InlineBlockType {
  Formula = 'formula',
  Mention = 'mention',
}

export enum AlignType {
  Left = 'left',
  Center = 'center',
  Right = 'right',
}

export interface BlockData {
  bg_color?: string;
  font_color?: string;
  align?: AlignType;
}

export interface HeadingBlockData extends BlockData {
  level: number;
}

export interface NumberedListBlockData extends BlockData {
  number: number;
}

export interface TodoListBlockData extends BlockData {
  checked: boolean;
}

export interface ToggleListBlockData extends BlockData {
  collapsed: boolean;
}

export interface CodeBlockData extends BlockData {
  language: string;
}

export interface CalloutBlockData extends BlockData {
  icon: string;
}

export interface MathEquationBlockData extends BlockData {
  formula?: string;
}

export enum ImageType {
  Local = 0,
  Internal = 1,
  External = 2,
}

export interface ImageBlockData extends BlockData {
  url?: string;
  width?: number;
  align?: AlignType;
  image_type?: ImageType;
  height?: number;
}

export interface OutlineBlockData extends BlockData {
  depth?: number;
}

export interface TableBlockData extends BlockData {
  colDefaultWidth: number;
  colMinimumWidth: number;
  colsHeight: number;
  colsLen: number;
  rowDefaultHeight: number;
  rowsLen: number;
}

export interface TableCellBlockData extends BlockData {
  colPosition: number;
  height: number;
  rowPosition: number;
  width: number;
}

export enum MentionType {
  PageRef = 'page',
  Date = 'date',
}

export interface Mention {
  // inline page ref id
  page_id?: string;
  // reminder date ref id
  date?: string;

  type: MentionType;
}

export enum YjsEditorKey {
  data_section = 'data',
  document = 'document',
  database = 'database',
  workspace_database = 'databases',
  folder = 'folder',
  // eslint-disable-next-line @typescript-eslint/no-duplicate-enum-values
  database_row = 'data',
  user_awareness = 'user_awareness',
  blocks = 'blocks',
  page_id = 'page_id',
  meta = 'meta',
  children_map = 'children_map',
  text_map = 'text_map',
  text = 'text',
  delta = 'delta',

  block_id = 'id',
  block_type = 'ty',
  // eslint-disable-next-line @typescript-eslint/no-duplicate-enum-values
  block_data = 'data',
  block_parent = 'parent',
  block_children = 'children',
  block_external_id = 'external_id',
  block_external_type = 'external_type',
}

export interface YDoc extends Y.Doc {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  get(key: YjsEditorKey.data_section | string): YSharedRoot | any;
}

export interface YSharedRoot extends Y.Map<unknown> {
  get(key: YjsEditorKey.document): YDocument;
}

export interface YDocument extends Y.Map<unknown> {
  get(key: YjsEditorKey.blocks | YjsEditorKey.page_id | YjsEditorKey.meta): YBlocks | YMeta | string;
}

export interface YBlocks extends Y.Map<unknown> {
  get(key: BlockId): Y.Map<unknown>;
}

export interface YMeta extends Y.Map<unknown> {
  get(key: YjsEditorKey.children_map | YjsEditorKey.text_map): YChildrenMap | YTextMap;
}

export interface YChildrenMap extends Y.Map<unknown> {
  get(key: ChildrenId): Y.Array<BlockId>;
}

export interface YTextMap extends Y.Map<unknown> {
  get(key: ExternalId): Y.Text;
}
