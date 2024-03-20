import React, { FC, useCallback, useMemo } from 'react';
import { EditorNodeType, TextNode } from '$app/application/document/document.types';
import { ReactEditor, useSlate } from 'slate-react';
import { Editor, Element } from 'slate';
import CheckboxIcon from '$app/components/editor/components/blocks/todo_list/CheckboxIcon';
import ToggleIcon from '$app/components/editor/components/blocks/toggle_list/ToggleIcon';
import NumberListIcon from '$app/components/editor/components/blocks/numbered_list/NumberListIcon';
import BulletedListIcon from '$app/components/editor/components/blocks/bulleted_list/BulletedListIcon';

export function useStartIcon(node: TextNode) {
  const editor = useSlate();
  const path = ReactEditor.findPath(editor, node);
  const block = Editor.parent(editor, path)?.[0] as Element | null;

  const Component = useMemo(() => {
    if (!Element.isElement(block)) {
      return null;
    }

    switch (block.type) {
      case EditorNodeType.TodoListBlock:
        return CheckboxIcon;
      case EditorNodeType.ToggleListBlock:
        return ToggleIcon;
      case EditorNodeType.NumberedListBlock:
        return NumberListIcon;
      case EditorNodeType.BulletedListBlock:
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
