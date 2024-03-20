import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, TodoListNode } from '$app/application/document/document.types';

export const TodoList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TodoListNode>>(({ node, children, ...attributes }, ref) => {
    const { checked = false } = useMemo(() => node.data || {}, [node.data]);
    const className = useMemo(() => {
      return `flex w-full flex-col ${checked ? 'checked' : ''} ${attributes.className ?? ''}`;
    }, [attributes.className, checked]);

    return (
      <>
        <div {...attributes} ref={ref} className={className}>
          {children}
        </div>
      </>
    );
  })
);
