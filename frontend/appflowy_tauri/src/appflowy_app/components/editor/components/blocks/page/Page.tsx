import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, PageNode } from '$app/application/document/document.types';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';

export const Page = memo(
  forwardRef<HTMLDivElement, EditorElementProps<PageNode>>(({ node, children, ...attributes }, ref) => {
    const className = useMemo(() => {
      return `${attributes.className ?? ''} mb-2 text-4xl font-bold`;
    }, [attributes.className]);

    return (
      <div ref={ref} {...attributes} className={className}>
        <span className={'relative'}>
          <Placeholder className={'top-1.5'} node={node} />
          {children}
        </span>
      </div>
    );
  })
);

export default Page;
