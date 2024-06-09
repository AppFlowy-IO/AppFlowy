import { EditorElementProps, PageNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';

export const Page = memo(
  forwardRef<HTMLDivElement, EditorElementProps<PageNode>>(({ node: _, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `${attributes.className ?? ''} document-title pb-3 text-5xl font-bold`;
    }, [attributes.className]);

    return (
      <div ref={ref} {...attributes} className={className}>
        {children}
      </div>
    );
  })
);

export default Page;
