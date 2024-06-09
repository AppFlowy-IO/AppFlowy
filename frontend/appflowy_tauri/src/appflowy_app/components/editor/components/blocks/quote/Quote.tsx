import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, QuoteNode } from '$app/application/document/document.types';

export const QuoteList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<QuoteNode>>(({ node: _, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `flex w-full flex-col ml-3 border-l-[4px] border-fill-default pl-2 ${attributes.className ?? ''}`;
    }, [attributes.className]);

    return (
      <div {...attributes} ref={ref} className={className}>
        {children}
      </div>
    );
  })
);
