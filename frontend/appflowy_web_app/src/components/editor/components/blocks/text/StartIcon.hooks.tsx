import { BlockType } from '@/application/collab.type';
import { BulletedListIcon } from '@/components/editor/components/blocks/bulleted-list';
import { NumberListIcon } from '@/components/editor/components/blocks/numbered-list';
import QuoteIcon from '@/components/editor/components/blocks/quote/QuoteIcon';
import ToggleIcon from '@/components/editor/components/blocks/toggle-list/ToggleIcon';
import { TextNode } from '@/components/editor/editor.type';
import React, { FC, useCallback, useMemo } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { Editor, Element } from 'slate';
import CheckboxIcon from '@/components/editor/components/blocks/todo-list/CheckboxIcon';

export function useStartIcon(node: TextNode) {
  const editor = useSlate();
  const path = ReactEditor.findPath(editor, node);
  const block = Editor.parent(editor, path)?.[0] as Element | null;

  const Component = useMemo(() => {
    if (!Element.isElement(block)) {
      return null;
    }

    switch (block.type) {
      case BlockType.TodoListBlock:
        return CheckboxIcon;
      case BlockType.ToggleListBlock:
        return ToggleIcon;
      case BlockType.NumberedListBlock:
        return NumberListIcon;
      case BlockType.BulletedListBlock:
        return BulletedListIcon;
      case BlockType.QuoteBlock:
        return QuoteIcon;
      default:
        return null;
    }
  }, [block]) as FC<{ block: Element; className: string }> | null;

  const renderIcon = useCallback(() => {
    if (!Component || !block) {
      return null;
    }

    const classList = ['text-block-icon relative w-[24px]'];

    if (block.type === BlockType.QuoteBlock) {
      classList.push('h-full min-w-[24px]');
    } else {
      classList.push('h-6');
    }

    return <Component className={classList.join(' ')} block={block} />;
  }, [Component, block]);

  return {
    hasStartIcon: !!Component,
    renderIcon,
  };
}
