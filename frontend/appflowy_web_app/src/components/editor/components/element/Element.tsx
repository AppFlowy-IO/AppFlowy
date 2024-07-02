import { BlockData, BlockType, InlineBlockType, YjsEditorKey } from '@/application/collab.type';
import { BulletedList } from '@/components/editor/components/blocks/bulleted-list';
import { Callout } from '@/components/editor/components/blocks/callout';
import { CodeBlock } from '@/components/editor/components/blocks/code';
import { DatabaseBlock } from '@/components/editor/components/blocks/database';
import { DividerNode } from '@/components/editor/components/blocks/divider';
import { Heading } from '@/components/editor/components/blocks/heading';
import { ImageBlock } from '@/components/editor/components/blocks/image';
import { LinkPreview } from '@/components/editor/components/blocks/link-preview';
import { MathEquation } from '@/components/editor/components/blocks/math-equation';
import { NumberedList } from '@/components/editor/components/blocks/numbered-list';
import { Outline } from '@/components/editor/components/blocks/outline';
import { Page } from '@/components/editor/components/blocks/page';
import { Paragraph } from '@/components/editor/components/blocks/paragraph';
import { Quote } from '@/components/editor/components/blocks/quote';
import { TableBlock, TableCellBlock } from '@/components/editor/components/blocks/table';
import { Text } from '@/components/editor/components/blocks/text';
import { ElementFallbackRender } from '@/components/error/ElementFallbackRender';
import { Skeleton } from '@mui/material';
import { ErrorBoundary } from 'react-error-boundary';
import { TodoList } from 'src/components/editor/components/blocks/todo-list';
import { ToggleList } from 'src/components/editor/components/blocks/toggle-list';
import { UnSupportedBlock } from '@/components/editor/components/element/UnSupportedBlock';
import { Formula } from '@/components/editor/components/leaf/formula';
import { Mention } from '@/components/editor/components/leaf/mention';
import { EditorElementProps, TextNode } from '@/components/editor/editor.type';
import { renderColor } from '@/utils/color';
import React, { FC, memo, Suspense, useMemo } from 'react';
import { RenderElementProps } from 'slate-react';
import isEqual from 'lodash-es/isEqual';

export const Element = memo(
  ({
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
        case BlockType.GridBlock:
        case BlockType.BoardBlock:
        case BlockType.CalendarBlock:
          return DatabaseBlock;
        case BlockType.LinkPreview:
          return LinkPreview;
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

      return `block-element relative flex rounded ${align ? `block-align-${align}` : ''}`;
    }, [node.data]);

    const style = useMemo(() => {
      const data = (node.data as BlockData) || {};

      return {
        backgroundColor: data.bgColor ? renderColor(data.bgColor) : undefined,
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
      <Suspense fallback={<Skeleton width={'100%'} height={24} />}>
        <ErrorBoundary fallbackRender={ElementFallbackRender}>
          <div {...attributes} data-block-type={node.type} className={className}>
            <Component style={style} className={`flex w-full flex-col`} node={node}>
              {children}
            </Component>
          </div>
        </ErrorBoundary>
      </Suspense>
    );
  },
  (prevProps, nextProps) => isEqual(prevProps.element, nextProps.element)
);
