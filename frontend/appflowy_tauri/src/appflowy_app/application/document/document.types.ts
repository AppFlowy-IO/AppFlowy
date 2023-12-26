import { Op } from 'quill-delta';
import { HTMLAttributes } from 'react';
import { Element } from 'slate';
import { ViewIconTypePB, ViewLayoutPB } from '@/services/backend';
import { YXmlText } from 'yjs/dist/src/types/YXmlText';

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
  type: EditorNodeType.HeadingBlock;
  data: {
    level: number;
  } & BlockData;
}

export interface GridNode extends Element {
  type: EditorNodeType.GridBlock;
  data: {
    viewId?: string;
  } & BlockData;
}

export interface TodoListNode extends Element {
  type: EditorNodeType.TodoListBlock;
  data: {
    checked: boolean;
  } & BlockData;
}

export interface CodeNode extends Element {
  type: EditorNodeType.CodeBlock;
  data: {
    language: string;
  } & BlockData;
}

export interface QuoteNode extends Element {
  type: EditorNodeType.QuoteBlock;
}

export interface NumberedListNode extends Element {
  type: EditorNodeType.NumberedListBlock;
}

export interface BulletedListNode extends Element {
  type: EditorNodeType.BulletedListBlock;
}

export interface ToggleListNode extends Element {
  type: EditorNodeType.ToggleListBlock;
  data: {
    collapsed: boolean;
  } & BlockData;
}

export interface DividerNode extends Element {
  type: EditorNodeType.DividerBlock;
}

export interface CalloutNode extends Element {
  type: EditorNodeType.CalloutBlock;
  data: {
    icon: string;
  } & BlockData;
}

export interface MathEquationNode extends Element {
  type: EditorNodeType.EquationBlock;
  data: {
    formula?: string;
  } & BlockData;
}

export interface FormulaNode extends Element {
  type: EditorInlineNodeType.Formula;
  data: boolean;
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
  icon?: {
    ty: ViewIconTypePB;
    value: string;
  };
}

export interface EditorProps {
  id: string;
  sharedType?: YXmlText;
  title?: string;
  onTitleChange?: (title: string) => void;
  showTitle?: boolean;
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

export interface EditorInlineAttributes {
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strikethrough?: boolean;
  font_color?: string;
  bg_color?: string;
  href?: string;
  code?: boolean;
  formula?: boolean;
  prism_token?: string;
  mention?: {
    type: string;
    // inline page ref id
    page?: string;
    // reminder date ref id
    date?: string;
  };
}

export enum EditorMarkFormat {
  Bold = 'bold',
  Italic = 'italic',
  Underline = 'underline',
  StrikeThrough = 'strikethrough',
  Code = 'code',
  Formula = 'formula',
}

export enum EditorStyleFormat {
  FontColor = 'font_color',
  BackgroundColor = 'bg_color',
  Href = 'href',
}

export enum EditorTurnFormat {
  Paragraph = 'paragraph',
  Heading1 = 'heading1', // 'heading1' is a special format, it's not a slate node type, but a slate node type's data
  Heading2 = 'heading2',
  Heading3 = 'heading3',
  TodoList = 'todo_list',
  BulletedList = 'bulleted_list',
  NumberedList = 'numbered_list',
  Quote = 'quote',
  ToggleList = 'toggle_list',
}

export enum MentionType {
  PageRef = 'page',
  Date = 'date',
}

export interface Mention {
  // inline page ref id
  page?: string;
  // reminder date ref id
  date?: string;
}
