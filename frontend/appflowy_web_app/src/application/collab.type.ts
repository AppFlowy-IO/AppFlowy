import * as Y from 'yjs';

export type BlockId = string;

export type ExternalId = string;

export type ChildrenId = string;

export type ViewId = string;

export type RowId = string;

export type CellId = string;

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
  BoardBlock = 'board',
  CalendarBlock = 'calendar',
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

export interface DatabaseNodeData extends BlockData {
  view_id: ViewId;
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

export enum DocCoverType {
  Color = 'CoverType.color',
  Image = 'CoverType.file',
  Asset = 'CoverType.asset',
}

export type DocCover = {
  image_type?: ImageType;
  cover_selection_type?: DocCoverType;
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
  empty = 'empty',

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
  extra = 'extra',
  cover = 'cover',
  line_height_layout = 'line_height_layout',
  font_layout = 'font_layout',
  type = 'ty',
  value = 'value',
  layout = 'layout',
  bid = 'bid',
}

export enum YjsDatabaseKey {
  views = 'views',
  id = 'id',
  metas = 'metas',
  fields = 'fields',
  is_primary = 'is_primary',
  last_modified = 'last_modified',
  created_at = 'created_at',
  name = 'name',
  type = 'ty',
  type_option = 'type_option',
  content = 'content',
  data = 'data',
  iid = 'iid',
  database_id = 'database_id',
  field_orders = 'field_orders',
  field_settings = 'field_settings',
  visibility = 'visibility',
  wrap = 'wrap',
  width = 'width',
  filters = 'filters',
  groups = 'groups',
  layout = 'layout',
  layout_settings = 'layout_settings',
  modified_at = 'modified_at',
  row_orders = 'row_orders',
  sorts = 'sorts',
  height = 'height',
  cells = 'cells',
  field_type = 'field_type',
  end_timestamp = 'end_timestamp',
  include_time = 'include_time',
  is_range = 'is_range',
  reminder_id = 'reminder_id',
  time_format = 'time_format',
  date_format = 'date_format',
  calculations = 'calculations',
  field_id = 'field_id',
  calculation_value = 'calculation_value',
  condition = 'condition',
  format = 'format',
  filter_type = 'filter_type',
  visible = 'visible',
  hide_ungrouped_column = 'hide_ungrouped_column',
  collapse_hidden_groups = 'collapse_hidden_groups',
  first_day_of_week = 'first_day_of_week',
  show_week_numbers = 'show_week_numbers',
  show_weekends = 'show_weekends',
  layout_ty = 'layout_ty',
}

export interface YDoc extends Y.Doc {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  getMap(key: YjsEditorKey.data_section): YSharedRoot | any;
}

export interface YDatabaseRow extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): RowId;

  get(key: YjsDatabaseKey.height): string;

  get(key: YjsDatabaseKey.visibility): boolean;

  get(key: YjsDatabaseKey.created_at): CreatedAt;

  get(key: YjsDatabaseKey.last_modified): LastModified;

  get(key: YjsDatabaseKey.cells): YDatabaseCells;
}

export interface YDatabaseCells extends Y.Map<unknown> {
  get(key: FieldId): YDatabaseCell;
}

export type EndTimestamp = string;
export type ReminderId = string;

export interface YDatabaseCell extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.created_at): CreatedAt;

  get(key: YjsDatabaseKey.last_modified): LastModified;

  get(key: YjsDatabaseKey.field_type): string;

  get(key: YjsDatabaseKey.data): object | string | boolean | number;

  get(key: YjsDatabaseKey.end_timestamp): EndTimestamp;

  get(key: YjsDatabaseKey.include_time): boolean;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.is_range): boolean;

  get(key: YjsDatabaseKey.reminder_id): ReminderId;
}

export interface YSharedRoot extends Y.Map<unknown> {
  get(key: YjsEditorKey.document): YDocument;

  get(key: YjsEditorKey.folder): YFolder;

  get(key: YjsEditorKey.database): YDatabase;

  get(key: YjsEditorKey.database_row): YDatabaseRow;
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

  get(key: YjsFolderKey.bid): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.name): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsFolderKey.icon | YjsFolderKey.extra): string;

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

export interface YDatabase extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.views): YDatabaseViews;

  get(key: YjsDatabaseKey.metas): YDatabaseMetas;

  get(key: YjsDatabaseKey.fields): YDatabaseFields;

  get(key: YjsDatabaseKey.id): string;
}

export interface YDatabaseViews extends Y.Map<unknown> {
  get(key: ViewId): YDatabaseView;
}

export type DatabaseId = string;
export type CreatedAt = string;
export type LastModified = string;
export type ModifiedAt = string;
export type FieldId = string;

export enum DatabaseViewLayout {
  Grid = 0,
  Board = 1,
  Calendar = 2,
}

export interface YDatabaseView extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.database_id): DatabaseId;

  get(key: YjsDatabaseKey.name): string;

  get(key: YjsDatabaseKey.created_at): CreatedAt;

  get(key: YjsDatabaseKey.modified_at): ModifiedAt;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.layout): string;

  get(key: YjsDatabaseKey.layout_settings): YDatabaseLayoutSettings;

  get(key: YjsDatabaseKey.filters): YDatabaseFilters;

  get(key: YjsDatabaseKey.groups): YDatabaseGroups;

  get(key: YjsDatabaseKey.sorts): YDatabaseSorts;

  get(key: YjsDatabaseKey.field_settings): YDatabaseFieldSettings;

  get(key: YjsDatabaseKey.field_orders): YDatabaseFieldOrders;

  get(key: YjsDatabaseKey.row_orders): YDatabaseRowOrders;

  get(key: YjsDatabaseKey.calculations): YDatabaseCalculations;
}

export type YDatabaseFieldOrders = Y.Array<unknown>; // [ { id: FieldId } ]

export type YDatabaseRowOrders = Y.Array<YDatabaseRowOrder>; // [ { id: RowId, height: number } ]

export type YDatabaseGroups = Y.Array<YDatabaseGroup>;

export type YDatabaseFilters = Y.Array<YDatabaseFilter>;

export type YDatabaseSorts = Y.Array<YDatabaseSort>;

export type YDatabaseCalculations = Y.Array<YDatabaseCalculation>;

export type SortId = string;

export type GroupId = string;

export interface YDatabaseLayoutSettings extends Y.Map<unknown> {
  // DatabaseViewLayout.Board
  get(key: '1'): YDatabaseBoardLayoutSetting;

  // DatabaseViewLayout.Calendar
  get(key: '2'): YDatabaseCalendarLayoutSetting;
}

export interface YDatabaseBoardLayoutSetting extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.hide_ungrouped_column | YjsDatabaseKey.collapse_hidden_groups): boolean;
}

export interface YDatabaseCalendarLayoutSetting extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.first_day_of_week | YjsDatabaseKey.field_id | YjsDatabaseKey.layout_ty): string;

  get(key: YjsDatabaseKey.show_week_numbers | YjsDatabaseKey.show_weekends): boolean;
}

export interface YDatabaseGroup extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): GroupId;

  get(key: YjsDatabaseKey.field_id): FieldId;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.content): string;

  get(key: YjsDatabaseKey.groups): YDatabaseGroupColumns;
}

export type YDatabaseGroupColumns = Y.Array<YDatabaseGroupColumn>;

export interface YDatabaseGroupColumn extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): string;

  get(key: YjsDatabaseKey.visible): boolean;
}

export interface YDatabaseRowOrder extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): SortId;

  get(key: YjsDatabaseKey.height): number;
}

export interface YDatabaseSort extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): SortId;

  get(key: YjsDatabaseKey.field_id): FieldId;

  get(key: YjsDatabaseKey.condition): string;
}

export type FilterId = string;

export interface YDatabaseFilter extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.id): FilterId;

  get(key: YjsDatabaseKey.field_id): FieldId;

  get(key: YjsDatabaseKey.type | YjsDatabaseKey.condition | YjsDatabaseKey.content | YjsDatabaseKey.filter_type): string;
}

export interface YDatabaseCalculation extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.field_id): FieldId;

  get(key: YjsDatabaseKey.id | YjsDatabaseKey.type | YjsDatabaseKey.calculation_value): string;
}

export interface YDatabaseFieldSettings extends Y.Map<unknown> {
  get(key: FieldId): YDatabaseFieldSetting;
}

export interface YDatabaseFieldSetting extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.visibility): string;

  get(key: YjsDatabaseKey.wrap): boolean;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.width): string;
}

export interface YDatabaseMetas extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.iid): string;
}

export interface YDatabaseFields extends Y.Map<unknown> {
  get(key: FieldId): YDatabaseField;
}

export interface YDatabaseField extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.name): string;

  get(key: YjsDatabaseKey.id): FieldId;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.type): string;

  get(key: YjsDatabaseKey.type_option): YDatabaseFieldTypeOption;

  get(key: YjsDatabaseKey.is_primary): boolean;

  get(key: YjsDatabaseKey.last_modified): LastModified;
}

export interface YDatabaseFieldTypeOption extends Y.Map<unknown> {
  // key is the field type
  get(key: string): YMapFieldTypeOption;
}

export interface YMapFieldTypeOption extends Y.Map<unknown> {
  get(key: YjsDatabaseKey.content): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.data): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.time_format): string;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.date_format): string;

  get(key: YjsDatabaseKey.database_id): DatabaseId;

  // eslint-disable-next-line @typescript-eslint/unified-signatures
  get(key: YjsDatabaseKey.format): string;
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
  // from local changes and never sync to remote. used for read-only mode
  Local = 'local',
  // from remote changes and never sync to remote.
  Remote = 'remote',
  // from local changes and sync to remote. used for collaborative mode
  LocalSync = 'local_sync',
}

export const layoutMap = {
  [ViewLayout.Document]: 'document',
  [ViewLayout.Grid]: 'grid',
  [ViewLayout.Board]: 'board',
  [ViewLayout.Calendar]: 'calendar',
};

export const databaseLayoutMap = {
  [DatabaseViewLayout.Grid]: 'grid',
  [DatabaseViewLayout.Board]: 'board',
  [DatabaseViewLayout.Calendar]: 'calendar',
};

export enum FontLayout {
  small = 'small',
  normal = 'normal',
  large = 'large',
}

export enum LineHeightLayout {
  small = 'small',
  normal = 'normal',
  large = 'large',
}
