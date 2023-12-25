import React, { forwardRef, memo } from 'react';
import { EditorElementProps, ParagraphNode } from '$app/application/document/document.types';

export const Paragraph = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ParagraphNode>>(({ node: _, children, ...attributes }, ref) => {
    {
      return (
        <div ref={ref} {...attributes} className={`${attributes.className ?? ''}`}>
          {children}
        </div>
      );
    }
  })
);
