import React, { forwardRef, memo } from 'react';
import { EditorElementProps, ToggleListNode } from '$app/application/document/document.types';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed } = node.data;
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
