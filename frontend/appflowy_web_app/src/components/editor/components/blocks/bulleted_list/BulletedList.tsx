import { BulletedListNode, EditorElementProps } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

export const BulletedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<BulletedListNode>>(
    ({ node: _, children, className, ...attributes }, ref) => {
      return (
        <div ref={ref} {...attributes} className={`${className}`}>
          {children}
        </div>
      );
    }
  )
);

export default BulletedList;
