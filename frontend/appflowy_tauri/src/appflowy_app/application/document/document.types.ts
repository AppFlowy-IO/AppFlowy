import { Op } from 'quill-delta';
import { HTMLAttributes } from 'react';
import { Element } from 'slate';
import { ViewIconTypePB, ViewLayoutPB } from '@/services/backend';
import { PageCover } from '$app_reducers/pages/slice';
import * as Y from 'yjs';

export interface EditorNode {
  id: string;
  type: EditorNodeType;
  parent?: string | null;
  data?: BlockData;
  children?: string;
  externalId?: string;
  externalType?: string;
}

export interface TextNode extends Element {
  type: EditorNodeType.Text;
  textId: string;
  blockId: string;
}

export interface PageNode extends Element {
  type: EditorNodeType.Page;
}
export interface ParagraphNode extends Element {
  type: EditorNodeType.Paragraph;
}

export type BlockData = {
  [key: string]: string | boolean | number | undefined;
  font_color?: string;
  bg_color?: string;
};

export interface HeadingNode extends Element {
  blockId: string;
  type: EditorNodeType.HeadingBlock;
  data: {
    level: number;
  } & BlockData;
}

export interface GridNode extends Element {
  blockId: string;
  type: EditorNodeType.GridBlock;
  data: {
    viewId?: string;
  } & BlockData;
}

export interface TodoListNode extends Element {
  blockId: string;
  type: EditorNodeType.TodoListBlock;
  data: {
    checked: boolean;
  } & BlockData;
}

export interface CodeNode extends Element {
  blockId: string;
  type: EditorNodeType.CodeBlock;
  data: {
    language: string;
  } & BlockData;
}

export interface QuoteNode extends Element {
  blockId: string;
  type: EditorNodeType.QuoteBlock;
}

export interface NumberedListNode extends Element {
  type: EditorNodeType.NumberedListBlock;
  blockId: string;
  data: {
    number?: number;
  } & BlockData;
}

export interface BulletedListNode extends Element {
  type: EditorNodeType.BulletedListBlock;
  blockId: string;
}

export interface ToggleListNode extends Element {
  type: EditorNodeType.ToggleListBlock;
  blockId: string;
  data: {
    collapsed: boolean;
  } & BlockData;
}

export interface DividerNode extends Element {
  type: EditorNodeType.DividerBlock;
  blockId: string;
}

export interface CalloutNode extends Element {
  type: EditorNodeType.CalloutBlock;
  blockId: string;
  data: {
    icon: string;
  } & BlockData;
}

export interface MathEquationNode extends Element {
  type: EditorNodeType.EquationBlock;
  blockId: string;
  data: {
    formula?: string;
  } & BlockData;
}

export enum ImageType {
  Local = 0,
  Internal = 1,
  External = 2,
}

export interface ImageNode extends Element {
  type: EditorNodeType.ImageBlock;
  blockId: string;
  data: {
    url?: string;
    width?: number;
    image_type?: ImageType;
    height?: number;
  } & BlockData;
}

export interface FormulaNode extends Element {
  type: EditorInlineNodeType.Formula;
  data: string;
}

export interface MentionNode extends Element {
  type: EditorInlineNodeType.Mention;
  data: Mention;
}

export interface EditorData {
  viewId: string;
  rootId: string;
  // key: block's id, value: block
  nodeMap: Record<string, EditorNode>;
  // key: block's children id, value: block's id
  childrenMap: Record<string, string[]>;
  // key: block's children id, value: block's id
  relativeMap: Record<string, string>;
  // key: block's externalId, value: delta
  deltaMap: Record<string, Op[]>;
  // key: block's externalId, value: block's id
  externalIdMap: Record<string, string>;
}

export interface MentionPage {
  id: string;
  name: string;
  layout: ViewLayoutPB;
  parentId: string;
  icon?: {
    ty: ViewIconTypePB;
    value: string;
  };
}

export interface EditorProps {
  title?: string;
  cover?: PageCover;
  onTitleChange?: (title: string) => void;
  onCoverChange?: (cover?: PageCover) => void;
  showTitle?: boolean;
  id: string;
  disableFocus?: boolean;
}

export interface LocalEditorProps {
  disableFocus?: boolean;
  sharedType: Y.XmlText;
  id: string;
  caretColor?: string;
}

export enum EditorNodeType {
  Text = 'text',
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
}

export enum EditorInlineNodeType {
  Mention = 'mention',
  Formula = 'formula',
}

export const inlineNodeTypes: (string | EditorInlineNodeType)[] = [
  EditorInlineNodeType.Mention,
  EditorInlineNodeType.Formula,
];

export interface EditorElementProps<T = Element> extends HTMLAttributes<HTMLDivElement> {
  node: T;
}

export enum EditorMarkFormat {
  Bold = 'bold',
  Italic = 'italic',
  Underline = 'underline',
  StrikeThrough = 'strikethrough',
  Code = 'code',
  Href = 'href',
  FontColor = 'font_color',
  BgColor = 'bg_color',
  Align = 'align',
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
