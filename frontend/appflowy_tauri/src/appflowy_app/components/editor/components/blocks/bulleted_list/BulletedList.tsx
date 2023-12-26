import React, { forwardRef, memo } from 'react';
import { EditorElementProps, BulletedListNode } from '$app/application/document/document.types';

export const BulletedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<BulletedListNode>>(
    ({ node: _, children, className, ...attributes }, ref) => {
      return (
        <>
          <span contentEditable={false} className={'absolute flex w-6 select-none justify-center font-medium'}>
            •
          </span>
          <div ref={ref} {...attributes} className={`${className} ml-6`}>
            {children}
          </div>
        </>
      );
    }
  )
);
