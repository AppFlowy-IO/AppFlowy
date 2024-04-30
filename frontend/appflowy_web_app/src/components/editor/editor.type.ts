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
  OutlineBlockData,
  TableBlockData,
  TableCellBlockData,
  BlockId,
  BlockData,
} from '@/application/collab.type';
import { HTMLAttributes } from 'react';
import { Element } from 'slate';

export interface BlockNode extends Element {
  blockId: BlockId;
  type: BlockType;
  data?: BlockData;
}

export interface TextNode extends Element {
  type: YjsEditorKey.text;
  textId: string;
}

export interface PageNode extends BlockNode {
  type: BlockType.Page;
}

export interface ParagraphNode extends BlockNode {
  type: BlockType.Paragraph;
}

export interface HeadingNode extends BlockNode {
  blockId: string;
  type: BlockType.HeadingBlock;
  data: HeadingBlockData;
}

export interface DividerNode extends BlockNode {
  type: BlockType.DividerBlock;
  blockId: string;
}

export interface TodoListNode extends BlockNode {
  type: BlockType.TodoListBlock;
  blockId: string;
  data: TodoListBlockData;
}

export interface ToggleListNode extends BlockNode {
  type: BlockType.ToggleListBlock;
  blockId: string;
  data: ToggleListBlockData;
}

export interface BulletedListNode extends BlockNode {
  type: BlockType.BulletedListBlock;
  blockId: string;
}

export interface NumberedListNode extends BlockNode {
  type: BlockType.NumberedListBlock;
  blockId: string;
  data: NumberedListBlockData;
}

export interface QuoteNode extends BlockNode {
  type: BlockType.QuoteBlock;
  blockId: string;
}

export interface CodeNode extends BlockNode {
  type: BlockType.CodeBlock;
  blockId: string;
  data: CodeBlockData;
}

export interface CalloutNode extends BlockNode {
  type: BlockType.CalloutBlock;
  blockId: string;
  data: CalloutBlockData;
}

export interface MathEquationNode extends BlockNode {
  type: BlockType.EquationBlock;
  blockId: string;
  data: MathEquationBlockData;
}

export interface ImageBlockNode extends BlockNode {
  type: BlockType.ImageBlock;
  blockId: string;
  data: ImageBlockData;
}

export interface OutlineNode extends BlockNode {
  type: BlockType.OutlineBlock;
  blockId: string;
  data: OutlineBlockData;
}

export interface TableNode extends BlockNode {
  type: BlockType.TableBlock;
  blockId: string;
  data: TableBlockData;
}

export interface TableCellNode extends BlockNode {
  type: BlockType.TableCell;
  blockId: string;
  data: TableCellBlockData;
}

export interface EditorElementProps<T = Element> extends HTMLAttributes<HTMLDivElement> {
  node: T;
}

type FormulaValue = string;

export interface FormulaNode extends Element {
  type: InlineBlockType.Formula;
  data: FormulaValue;
}

export interface MentionNode extends Element {
  type: InlineBlockType.Mention;
  data: Mention;
}
