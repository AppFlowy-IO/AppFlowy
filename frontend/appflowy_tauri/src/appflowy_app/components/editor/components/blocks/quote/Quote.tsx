import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, QuoteNode } from '$app/application/document/document.types';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';

export const QuoteList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<QuoteNode>>(({ node, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `${attributes.className ?? ''} relative border-l-4 border-fill-default`;
    }, [attributes.className]);

    return (
      <div {...attributes} ref={ref} className={className}>
        <span className={'relative left-2'}>
          <Placeholder node={node} />
          {children}
        </span>
      </div>
    );
  })
);
