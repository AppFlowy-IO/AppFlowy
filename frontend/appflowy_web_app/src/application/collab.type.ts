import Y from 'yjs';

export type BlockId = string;

export type ExternalId = string;

export type ChildrenId = string;

export type ViewId = string;

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
  reminder_id?: string;
  reminder_option?: string;

  type: MentionType;
}

export interface FolderMeta {
  current_view: ViewId;
  current_workspace: string;
}

export enum CoverType {
  Color = 'CoverType.color',
  Image = 'CoverType.file',
  Asset = 'CoverType.asset',
}

export type PageCover = {
  image_type?: ImageType;
  cover_selection_type?: CoverType;
  cover_selection?: string;
} | null;

export enum ViewLayout {
  Document = 0,
  Grid = 1,
  Board = 2,
  Calendar = 3,
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

  // document
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

export enum YjsFolderKey {
  views = 'views',
  relation = 'relation',
  section = 'section',
  private = 'private',
  favorite = 'favorite',
  recent = 'recent',
  trash = 'trash',
  meta = 'meta',
  current_view = 'current_view',
  current_workspace = 'current_workspace',
  id = 'id',
  name = 'name',
  icon = 'icon',
  type = 'ty',
  value = 'value',
  layout = 'layout',
}

export interface YDoc extends Y.Doc {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  getMap(key: YjsEditorKey.data_section): YSharedRoot | any;
}

export interface YSharedRoot extends Y.Map<unknown> {
  get(key: YjsEditorKey.document): YDocument;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsEditorKey.folder): YFolder;
}

export interface YFolder extends Y.Map<unknown> {
  get(key: YjsFolderKey.views): YViews;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.meta): YFolderMeta;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.relation): YFolderRelation;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.section): YFolderSection;
}

export interface YViews extends Y.Map<unknown> {
  get(key: ViewId): YView;
}

export interface YView extends Y.Map<unknown> {
  get(key: YjsFolderKey.id): ViewId;

  get(key: YjsFolderKey.name): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.icon): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.layout): string;
}

export interface YFolderRelation extends Y.Map<unknown> {
  get(key: ViewId): Y.Array<ViewId>;
}

export interface YFolderMeta extends Y.Map<unknown> {
  get(key: YjsFolderKey.current_view | YjsFolderKey.current_workspace): string;
}

export interface YFolderSection extends Y.Map<unknown> {
  get(key: YjsFolderKey.favorite | YjsFolderKey.private | YjsFolderKey.recent | YjsFolderKey.trash): YFolderSectionItem;
}

export interface YFolderSectionItem extends Y.Map<unknown> {
  get(key: string): Y.Array<unknown>;
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

export enum CollabType {
  Document = 0,
  Database = 1,
  WorkspaceDatabase = 2,
  Folder = 3,
  DatabaseRow = 4,
  UserAwareness = 5,
  Empty = 6,
}

export enum CollabOrigin {
  Local = 'local',
  Remote = 'remote',
}

export const layoutMap = {
  [ViewLayout.Document]: 'document',
  [ViewLayout.Grid]: 'grid',
  [ViewLayout.Board]: 'board',
  [ViewLayout.Calendar]: 'calendar',
};
