import { EditorElementProps, ParagraphNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

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
