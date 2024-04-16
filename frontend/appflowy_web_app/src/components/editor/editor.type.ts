import {
  BlockType,
  CalloutBlockData,
  CodeBlockData,
  HeadingBlockData,
  ImageBlockData,
  MathEquationBlockData,
  NumberedListBlockData,
  TodoListBlockData,
  ToggleListBlockData,
  YjsEditorKey,
  InlineBlockType,
  Mention,
} from '@/application/document.type';
import { HTMLAttributes } from 'react';
import { Element } from 'slate';

export interface TextNode extends Element {
  type: YjsEditorKey.text;
  textId: string;
  blockId: string;
}

export interface PageNode extends Element {
  type: BlockType.Page;
}

export interface ParagraphNode extends Element {
  type: BlockType.Paragraph;
}

export interface HeadingNode extends Element {
  blockId: string;
  type: BlockType.HeadingBlock;
  data: HeadingBlockData;
}

export interface DividerNode extends Element {
  type: BlockType.DividerBlock;
  blockId: string;
}

export interface TodoListNode extends Element {
  type: BlockType.TodoListBlock;
  blockId: string;
  data: TodoListBlockData;
}

export interface ToggleListNode extends Element {
  type: BlockType.ToggleListBlock;
  blockId: string;
  data: ToggleListBlockData;
}

export interface BulletedListNode extends Element {
  type: BlockType.BulletedListBlock;
  blockId: string;
}

export interface NumberedListNode extends Element {
  type: BlockType.NumberedListBlock;
  blockId: string;
  data: NumberedListBlockData;
}

export interface QuoteNode extends Element {
  type: BlockType.QuoteBlock;
  blockId: string;
}

export interface CodeNode extends Element {
  type: BlockType.CodeBlock;
  blockId: string;
  data: CodeBlockData;
}

export interface CalloutNode extends Element {
  type: BlockType.CalloutBlock;
  blockId: string;
  data: CalloutBlockData;
}

export interface MathEquationNode extends Element {
  type: BlockType.EquationBlock;
  blockId: string;
  data: MathEquationBlockData;
}

export interface ImageBlockNode extends Element {
  type: BlockType.ImageBlock;
  blockId: string;
  data: ImageBlockData;
}

export interface EditorElementProps<T = Element> extends HTMLAttributes<HTMLDivElement> {
  node: T;
}

export interface FormulaNode extends Element {
  type: InlineBlockType.Formula;
  data: string;
}

export interface MentionNode extends Element {
  type: InlineBlockType.Mention;
  data: Mention;
}
