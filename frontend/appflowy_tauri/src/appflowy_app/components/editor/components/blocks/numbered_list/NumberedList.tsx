import React, { forwardRef, memo } from 'react';
import { EditorElementProps, NumberedListNode } from '$app/application/document/document.types';

export const NumberedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<NumberedListNode>>(
    ({ node: _, children, className, ...attributes }, ref) => {
      return (
        <div ref={ref} {...attributes} className={`${className}`}>
          {children}
        </div>
      );
    }
  )
);
