import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '$app/application/document/document.types';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed } = useMemo(() => node.data || {}, [node.data]);
    const className = `${attributes.className ?? ''} flex w-full flex-col ${collapsed ? 'collapsed' : ''}`;

    return (
      <>
        <div {...attributes} ref={ref} className={className}>
          {children}
        </div>
      </>
    );
  })
);
