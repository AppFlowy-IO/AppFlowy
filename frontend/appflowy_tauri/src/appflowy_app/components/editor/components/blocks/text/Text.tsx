import React, { forwardRef, memo } from 'react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { EditorElementProps, TextNode } from '$app/application/document/document.types';

export const Text = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TextNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <div ref={ref} {...attributes} className={'text-element relative pb-1'}>
        <Placeholder node={node} />
        {children}
      </div>
    );
  })
);

export default Text;
