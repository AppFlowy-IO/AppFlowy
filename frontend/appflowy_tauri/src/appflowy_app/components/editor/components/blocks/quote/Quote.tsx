import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, QuoteNode } from '$app/application/document/document.types';

export const QuoteList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<QuoteNode>>(({ node: _, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `${attributes.className ?? ''} flex my-2 flex-1 flex-col border-l-4 border-fill-default pl-5`;
    }, [attributes.className]);

    return (
      <div {...attributes} ref={ref} className={className}>
        {children}
      </div>
    );
  })
);
