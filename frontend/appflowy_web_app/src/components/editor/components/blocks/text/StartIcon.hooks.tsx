import { BlockType } from '@/application/document.type';
import { BulletedListIcon } from '@/components/editor/components/blocks/bulleted_list';
import { NumberListIcon } from '@/components/editor/components/blocks/numbered_list';
import ToggleIcon from '@/components/editor/components/blocks/toggle_list/ToggleIcon';
import { TextNode } from '@/components/editor/editor.type';
import React, { FC, useCallback, useMemo } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { Editor, Element } from 'slate';
import CheckboxIcon from '../todo_list/CheckboxIcon';

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
      default:
        return null;
    }
  }, [block]) as FC<{ block: Element; className: string }> | null;

  const renderIcon = useCallback(() => {
    if (!Component || !block) {
      return null;
    }

    return <Component className={`text-block-icon relative`} block={block} />;
  }, [Component, block]);

  return {
    hasStartIcon: !!Component,
    renderIcon,
  };
}
