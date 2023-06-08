import Delta, { Op } from 'quill-delta';
import { BlockActionTypePB } from '@/services/backend';
import { Sources } from 'quill';
import React from 'react';

export interface DocumentBlockJSON {
  type: BlockType;
  data: BlockData<any>;
  children: DocumentBlockJSON[];
}

export interface RangeStatic {
  id: string;
  length: number;
  index: number;
}

export enum BlockType {
  PageBlock = 'page',
  HeadingBlock = 'heading',
  TextBlock = 'paragraph',
  TodoListBlock = 'todo_list',
  BulletedListBlock = 'bulleted_list',
  NumberedListBlock = 'numbered_list',
  ToggleListBlock = 'toggle_list',
  CodeBlock = 'code',
  EquationBlock = 'math_equation',
  EmbedBlock = 'embed',
  QuoteBlock = 'quote',
  CalloutBlock = 'callout',
  DividerBlock = 'divider',
  MediaBlock = 'media',
  TableBlock = 'table',
  ColumnBlock = 'column',
}

export interface HeadingBlockData extends TextBlockData {
  level: number;
}

export interface TodoListBlockData extends TextBlockData {
  checked: boolean;
}

export interface BulletListBlockData extends TextBlockData {
  format: 'default' | 'circle' | 'square' | 'disc';
}

export interface NumberedListBlockData extends TextBlockData {
  format: 'default' | 'numbers' | 'letters' | 'roman_numerals';
}

export interface ToggleListBlockData extends TextBlockData {
  collapsed: boolean;
}

export interface QuoteBlockData extends TextBlockData {
  size: 'default' | 'large';
}

export interface CalloutBlockData extends TextBlockData {
  icon: string;
}

export interface TextBlockData {
  delta: Op[];
}

export interface DividerBlockData {}

export type PageBlockData = TextBlockData;

export type BlockData<Type> = Type extends BlockType.HeadingBlock
  ? HeadingBlockData
  : Type extends BlockType.PageBlock
  ? PageBlockData
  : Type extends BlockType.TodoListBlock
  ? TodoListBlockData
  : Type extends BlockType.QuoteBlock
  ? QuoteBlockData
  : Type extends BlockType.BulletedListBlock
  ? BulletListBlockData
  : Type extends BlockType.NumberedListBlock
  ? NumberedListBlockData
  : Type extends BlockType.ToggleListBlock
  ? ToggleListBlockData
  : Type extends BlockType.DividerBlock
  ? DividerBlockData
  : Type extends BlockType.CalloutBlock
  ? CalloutBlockData
  : Type extends BlockType.TextBlock
  ? TextBlockData
  : any;

export interface NestedBlock<Type = any> {
  id: string;
  type: BlockType;
  data: BlockData<Type>;
  parent: string | null;
  children: string;
}

export type Node = NestedBlock;

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
}
export interface SlashCommandState {
  isSlashCommand: boolean;
  blockId?: string;
}

export interface RectSelectionState {
  selection: string[];
  isDragging: boolean;
}

export interface RangeState {
  anchor?: {
    id: string;
    point: {
      x: number;
      y: number;
      index?: number;
      length?: number;
    };
  };
  focus?: {
    id: string;
    point: {
      x: number;
      y: number;
    };
  };
  ranges: Partial<
    Record<
      string,
      {
        index: number;
        length: number;
      }
    >
  >;
  isDragging: boolean;
  caret?: RangeStatic;
}

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

export enum SplitRelationship {
  NextSibling,
  FirstChild,
}
export enum TextAction {
  Turn = 'turn',
  Bold = 'bold',
  Italic = 'italic',
  Underline = 'underline',
  Strikethrough = 'strikethrough',
  Code = 'code',
  Equation = 'equation',
}
export interface TextActionMenuProps {
  /**
   * The custom items that will be covered in the default items
   */
  customItems?: TextAction[];
  /**
   * The items that will be excluded from the default items
   */
  excludeItems?: TextAction[];
}

export interface BlockConfig {
  /**
   * Whether the block can have children
   */
  canAddChild: boolean;
  /**
   * The regexps that will be used to match the markdown flag
   */
  markdownRegexps?: RegExp[];

  /**
   * The default data of the block
   */
  defaultData?: BlockData<any>;

  /**
   * The props that will be passed to the text split function
   */
  splitProps?: {
    /**
     * The relationship between the next line block and the current block
     */
    nextLineRelationShip: SplitRelationship;
    /**
     * The type of the next line block
     */
    nextLineBlockType: BlockType;
  };

  /**
   * The props that will be passed to the text action menu
   */
  textActionMenuProps?: TextActionMenuProps;
}

export interface ControllerAction {
  action: BlockActionTypePB;
  payload: {
    block: { id: string; parent_id: string; children_id: string; data: string; ty: BlockType };
    parent_id: string;
    prev_id: string;
  };
}

export interface RangeStaticNoId {
  index: number;
  length: number;
}

export interface CodeEditorProps extends EditorProps {
  language: string;
}
export interface EditorProps {
  isCodeBlock?: boolean;
  placeholder?: string;
  value?: Delta;
  selection?: RangeStaticNoId;
  lastSelection?: RangeStaticNoId;
  onSelectionChange?: (range: RangeStaticNoId | null, oldRange: RangeStaticNoId | null, source?: Sources) => void;
  onChange?: (delta: Delta, oldDelta: Delta, source?: Sources) => void;
  onKeyDown?: (event: React.KeyboardEvent<HTMLDivElement>) => void;
}

export interface BlockCopyData {
  json: string;
  text: string;
  html: string;
}
