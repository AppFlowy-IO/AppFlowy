import React, { forwardRef, memo } from 'react';
import { EditorElementProps, CalloutNode } from '$app/application/document/document.types';
import CalloutIcon from '$app/components/editor/components/blocks/callout/CalloutIcon';

export const Callout = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CalloutNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <div
        {...attributes}
        className={`${
          attributes.className ?? ''
        } relative my-2 flex w-full items-start gap-3 rounded border border-solid border-line-divider bg-content-blue-50 p-2`}
        ref={ref}
      >
        <CalloutIcon node={node} />
        <div className={'flex-1'}>{children}</div>
      </div>
    );
  })
);
