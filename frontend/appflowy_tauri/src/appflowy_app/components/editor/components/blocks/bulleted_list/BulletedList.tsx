import React, { forwardRef, memo } from 'react';
import { EditorElementProps, BulletedListNode } from '$app/application/document/document.types';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';

export const BulletedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<BulletedListNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <div {...attributes} className={`${attributes.className ?? ''} relative`} ref={ref}>
        <span contentEditable={false} className={'pr-2 font-medium'}>
          •
        </span>
        <span className={'relative'}>
          <Placeholder node={node} />
          {children}
        </span>
      </div>
    );
  })
);
