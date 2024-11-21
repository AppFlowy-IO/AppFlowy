import { EditorElementProps, CalloutNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

export const Callout = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CalloutNode>>(({ node: _node, children, ...attributes }, ref) => {
    return (
      <>

        <div
          ref={ref}
          {...attributes}
          className={`${attributes.className ?? ''} flex w-full flex-col rounded border border-line-divider bg-fill-list-active py-2`}
        >
          {children}
        </div>
      </>
    );
  }),
);

export default Callout;
