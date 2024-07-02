import { EditorElementProps, QuoteNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';

export const Quote = memo(
  forwardRef<HTMLDivElement, EditorElementProps<QuoteNode>>(({ node: _, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `flex w-full flex-col pl-3 py-1 ${attributes.className ?? ''}`;
    }, [attributes.className]);

    return (
      <div {...attributes} ref={ref} className={className}>
        <span className={'w-full border-l-[4px] border-fill-default pl-2'}>{children}</span>
      </div>
    );
  })
);

export default Quote;
