import React, { forwardRef, memo } from 'react';
import { EditorElementProps, PageNode } from '$app/application/document/document.types';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';

export const Page = memo(
  forwardRef<HTMLDivElement, EditorElementProps<PageNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <div ref={ref} {...attributes} className={`${attributes.className ?? ''} mb-2 text-4xl font-bold`}>
        <span className={'relative'}>
          <Placeholder className={'top-1.5'} node={node} />
          {children}
        </span>
      </div>
    );
  })
);

export default Page;
