import { EditorElementProps, NumberedListNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

const NumberedList = memo(
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

export default NumberedList;
