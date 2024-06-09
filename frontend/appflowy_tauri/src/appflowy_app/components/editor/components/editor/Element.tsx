import React, { FC, HTMLAttributes, useMemo } from 'react';
import { RenderElementProps, useSlateStatic } from 'slate-react';
import {
  BlockData,
  EditorElementProps,
  EditorInlineNodeType,
  EditorNodeType,
  TextNode,
} from '$app/application/document/document.types';
import { Paragraph } from '$app/components/editor/components/blocks/paragraph';
import { Heading } from '$app/components/editor/components/blocks/heading';
import { TodoList } from '$app/components/editor/components/blocks/todo_list';
import { Code } from '$app/components/editor/components/blocks/code';
import { QuoteList } from '$app/components/editor/components/blocks/quote';
import { NumberedList } from '$app/components/editor/components/blocks/numbered_list';
import { BulletedList } from '$app/components/editor/components/blocks/bulleted_list';
import { DividerNode } from '$app/components/editor/components/blocks/divider';
import { InlineFormula } from '$app/components/editor/components/inline_nodes/inline_formula';
import { ToggleList } from '$app/components/editor/components/blocks/toggle_list';
import { Callout } from '$app/components/editor/components/blocks/callout';
import { Mention } from '$app/components/editor/components/inline_nodes/mention';
import { GridBlock } from '$app/components/editor/components/blocks/database';
import { MathEquation } from '$app/components/editor/components/blocks/math_equation';
import { ImageBlock } from '$app/components/editor/components/blocks/image';

import { Text as TextComponent } from '../blocks/text';
import { Page } from '../blocks/page';
import { useElementState } from '$app/components/editor/components/editor/Element.hooks';
import UnSupportBlock from '$app/components/editor/components/blocks/_shared/unSupportBlock';
import { renderColor } from '$app/utils/color';

function Element({ element, attributes, children }: RenderElementProps) {
  const node = element;

  const InlineComponent = useMemo(() => {
    switch (node.type) {
      case EditorInlineNodeType.Formula:
        return InlineFormula;
      case EditorInlineNodeType.Mention:
        return Mention;
      default:
        return null;
    }
  }, [node.type]) as FC<EditorElementProps>;

  const Component = useMemo(() => {
    switch (node.type) {
      case EditorNodeType.Page:
        return Page;
      case EditorNodeType.HeadingBlock:
        return Heading;
      case EditorNodeType.TodoListBlock:
        return TodoList;
      case EditorNodeType.Paragraph:
        return Paragraph;
      case EditorNodeType.CodeBlock:
        return Code;
      case EditorNodeType.QuoteBlock:
        return QuoteList;
      case EditorNodeType.NumberedListBlock:
        return NumberedList;
      case EditorNodeType.BulletedListBlock:
        return BulletedList;
      case EditorNodeType.DividerBlock:
        return DividerNode;
      case EditorNodeType.ToggleListBlock:
        return ToggleList;
      case EditorNodeType.CalloutBlock:
        return Callout;
      case EditorNodeType.GridBlock:
        return GridBlock;
      case EditorNodeType.EquationBlock:
        return MathEquation;
      case EditorNodeType.ImageBlock:
        return ImageBlock;
      default:
        return UnSupportBlock;
    }
  }, [node.type]) as FC<EditorElementProps & HTMLAttributes<HTMLElement>>;

  const editor = useSlateStatic();
  const { blockSelected } = useElementState(node);
  const isEmbed = editor.isEmbed(node);

  const className = useMemo(() => {
    const align =
      (
        node.data as {
          align: 'left' | 'center' | 'right';
        }
      )?.align || 'left';

    return `block-element flex rounded ${align ? `block-align-${align}` : ''} ${
      blockSelected && !isEmbed ? 'bg-content-blue-100' : ''
    }`;
  }, [node.data, blockSelected, isEmbed]);

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

  if (node.type === EditorNodeType.Text) {
    return (
      <TextComponent {...attributes} node={node as TextNode}>
        {children}
      </TextComponent>
    );
  }

  return (
    <div {...attributes} data-block-type={node.type} className={className}>
      <Component style={style} className={`flex w-full flex-col`} node={node}>
        {children}
      </Component>
    </div>
  );
}

export default Element;
