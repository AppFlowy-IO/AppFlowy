import { BlockData, BlockType, InlineBlockType, YjsEditorKey } from '@/application/collab.type';
import { BulletedList } from '@/components/editor/components/blocks/bulleted_list';
import { Callout } from '@/components/editor/components/blocks/callout';
import { CodeBlock } from '@/components/editor/components/blocks/code';
import { DividerNode } from '@/components/editor/components/blocks/divider';
import { Heading } from '@/components/editor/components/blocks/heading';
import { ImageBlock } from '@/components/editor/components/blocks/image';
import { MathEquation } from '@/components/editor/components/blocks/math_equation';
import { NumberedList } from '@/components/editor/components/blocks/numbered_list';
import { Outline } from '@/components/editor/components/blocks/outline';
import { Page } from '@/components/editor/components/blocks/page';
import { Paragraph } from '@/components/editor/components/blocks/paragraph';
import { Quote } from '@/components/editor/components/blocks/quote';
import { TableBlock, TableCellBlock } from '@/components/editor/components/blocks/table';
import { Text } from '@/components/editor/components/blocks/text';
import { TodoList } from '@/components/editor/components/blocks/todo_list';
import { ToggleList } from '@/components/editor/components/blocks/toggle_list';
import { UnSupportedBlock } from '@/components/editor/components/element/UnSupportedBlock';
import { Formula } from '@/components/editor/components/leaf/formula';
import { Mention } from '@/components/editor/components/leaf/mention';
import { EditorElementProps, TextNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { FC, useMemo } from 'react';
import { RenderElementProps } from 'slate-react';

export const Element = ({
  element: node,
  attributes,
  children,
}: RenderElementProps & {
  element: EditorElementProps['node'];
}) => {
  const Component = useMemo(() => {
    switch (node.type) {
      case BlockType.HeadingBlock:
        return Heading;
      case BlockType.TodoListBlock:
        return TodoList;
      case BlockType.ToggleListBlock:
        return ToggleList;
      case BlockType.Paragraph:
        return Paragraph;
      case BlockType.DividerBlock:
        return DividerNode;
      case BlockType.Page:
        return Page;
      case BlockType.QuoteBlock:
        return Quote;
      case BlockType.BulletedListBlock:
        return BulletedList;
      case BlockType.NumberedListBlock:
        return NumberedList;
      case BlockType.CodeBlock:
        return CodeBlock;
      case BlockType.CalloutBlock:
        return Callout;
      case BlockType.EquationBlock:
        return MathEquation;
      case BlockType.ImageBlock:
        return ImageBlock;
      case BlockType.OutlineBlock:
        return Outline;
      case BlockType.TableBlock:
        return TableBlock;
      case BlockType.TableCell:
        return TableCellBlock;
      default:
        return UnSupportedBlock;
    }
  }, [node.type]) as FC<EditorElementProps>;

  const InlineComponent = useMemo(() => {
    switch (node.type) {
      case InlineBlockType.Formula:
        return Formula;
      case InlineBlockType.Mention:
        return Mention;
      default:
        return null;
    }
  }, [node.type]) as FC<EditorElementProps>;

  const className = useMemo(() => {
    const data = (node.data as BlockData) || {};
    const align = data.align;

    return `block-element flex rounded ${align ? `block-align-${align}` : ''}`;
  }, [node.data]);

  const style = useMemo(() => {
    const data = (node.data as BlockData) || {};

    return {
      backgroundColor: data.bg_color ? renderColor(data.bg_color) : undefined,
      color: data.font_color ? renderColor(data.font_color) : undefined,
    };
  }, [node.data]);

  if (InlineComponent) {
    return (
      <InlineComponent {...attributes} node={node}>
        {children}
      </InlineComponent>
    );
  }

  if (node.type === YjsEditorKey.text) {
    return (
      <Text {...attributes} node={node as TextNode}>
        {children}
      </Text>
    );
  }

  return (
    <div {...attributes} data-block-type={node.type} className={className}>
      <Component style={style} className={`flex w-full flex-col`} node={node}>
        {children}
      </Component>
    </div>
  );
};
