import React, { forwardRef, memo } from 'react';
import { EditorElementProps, BulletedListNode } from '$app/application/document/document.types';

export const BulletedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<BulletedListNode>>(({ node: _, children, ...attributes }, ref) => {
    return (
      <>
        <span contentEditable={false} className={'pointer-events-none absolute font-medium'}>
          •
        </span>
        <div {...attributes} ref={ref} className={`flex flex-1 flex-col pl-6 ${attributes.className ?? ''}`}>
          {children}
        </div>
      </>
    );
  })
);
