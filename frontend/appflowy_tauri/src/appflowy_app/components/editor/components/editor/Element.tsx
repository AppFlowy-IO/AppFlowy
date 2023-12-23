import React, { FC, HTMLAttributes, useMemo } from 'react';
import { RenderElementProps } from 'slate-react';
import {
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
import { useSelectedBlock } from '$app/components/editor/components/editor/Editor.hooks';
import { Text as TextComponent } from '../blocks/text';
import { Page } from '../blocks/page';

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
      default:
        return Paragraph;
    }
  }, [node.type]) as FC<EditorElementProps & HTMLAttributes<HTMLElement>>;

  const isSelected = useSelectedBlock(node.blockId);

  if (InlineComponent) {
    return (
      <span {...attributes}>
        <InlineComponent node={node}>{children}</InlineComponent>
      </span>
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
    <div {...attributes} data-block-type={node.type} className={'block-element'}>
      <Component className={`flex w-full flex-col ${isSelected ? 'bg-content-blue-100' : ''}`} node={node}>
        {children}
      </Component>
    </div>
  );
}

export default Element;
