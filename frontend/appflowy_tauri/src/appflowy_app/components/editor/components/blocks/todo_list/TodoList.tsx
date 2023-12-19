import React, { forwardRef, memo, useCallback, useMemo } from 'react';
import { EditorElementProps, TodoListNode } from '$app/application/document/document.types';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import { useSlateStatic } from 'slate-react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { CustomEditor } from '$app/components/editor/command';

export const TodoList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TodoListNode>>(({ node, children, ...attributes }, ref) => {
    const { checked } = node.data;
    const editor = useSlateStatic();
    const className = useMemo(() => {
      return `relative ${attributes.className ?? ''}`;
    }, [attributes.className]);
    const toggleTodo = useCallback(() => {
      CustomEditor.toggleTodo(editor, node);
    }, [editor, node]);

    return (
      <div {...attributes} ref={ref} className={className}>
        <span
          data-playwright-selected={false}
          contentEditable={false}
          onClick={toggleTodo}
          className='absolute left-0 top-0 inline-flex cursor-pointer text-xl text-fill-default'
        >
          {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
        </span>

        <span className={`relative ml-6 ${checked ? 'text-text-caption line-through' : ''}`}>
          <Placeholder node={node} />
          {children}
        </span>
      </div>
    );
  })
);
