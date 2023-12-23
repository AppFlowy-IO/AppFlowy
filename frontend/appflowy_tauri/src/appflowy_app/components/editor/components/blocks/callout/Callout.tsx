import React, { forwardRef, memo } from 'react';
import { EditorElementProps, CalloutNode } from '$app/application/document/document.types';
import CalloutIcon from '$app/components/editor/components/blocks/callout/CalloutIcon';

export const Callout = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CalloutNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <>
        <div contentEditable={false} className={'absolute p-2'}>
          <CalloutIcon node={node} />
        </div>
        <div
          {...attributes}
          className={`${
            attributes.className ?? ''
          } my-2 flex-1 items-start rounded border border-solid border-line-divider bg-content-blue-50 py-1.5 pl-12`}
          ref={ref}
        >
          {children}
        </div>
      </>
    );
  })
);
