import React, { forwardRef, memo, useCallback, useMemo } from 'react';
import { EditorElementProps, TodoListNode } from '$app/application/document/document.types';
import { ReactComponent as CheckboxCheckSvg } from '$app/assets/database/checkbox-check.svg';
import { ReactComponent as CheckboxUncheckSvg } from '$app/assets/database/checkbox-uncheck.svg';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

export const TodoList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TodoListNode>>(({ node, children, ...attributes }, ref) => {
    const { checked } = node.data;
    const editor = useSlateStatic();
    const className = useMemo(() => {
      return `flex w-full flex-col pl-6 ${checked ? 'checked' : ''} ${attributes.className ?? ''}`;
    }, [attributes.className, checked]);
    const toggleTodo = useCallback(() => {
      CustomEditor.toggleTodo(editor, node);
    }, [editor, node]);

    return (
      <>
        <span
          data-playwright-selected={false}
          contentEditable={false}
          onClick={toggleTodo}
          className='absolute cursor-pointer select-none text-xl text-fill-default'
        >
          {checked ? <CheckboxCheckSvg /> : <CheckboxUncheckSvg />}
        </span>
        <div {...attributes} ref={ref} className={className}>
          {children}
        </div>
      </>
    );
  })
);
