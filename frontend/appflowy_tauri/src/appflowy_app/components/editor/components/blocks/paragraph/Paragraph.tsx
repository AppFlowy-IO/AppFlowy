import React, { forwardRef, memo } from 'react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { EditorElementProps, ParagraphNode } from '$app/application/document/document.types';

export const Paragraph = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ParagraphNode>>(({ node, children, ...attributes }, ref) => {
    {
      return (
        <div ref={ref} {...attributes} className={`${attributes.className ?? ''}`}>
          <span className={'relative'}>
            <Placeholder node={node} />
            {children}
          </span>
        </div>
      );
    }
  })
);
