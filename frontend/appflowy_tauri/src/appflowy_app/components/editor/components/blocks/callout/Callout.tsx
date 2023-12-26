import React, { forwardRef, memo } from 'react';
import { EditorElementProps, CalloutNode } from '$app/application/document/document.types';
import CalloutIcon from '$app/components/editor/components/blocks/callout/CalloutIcon';

export const Callout = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CalloutNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <>
        <div contentEditable={false} className={'absolute w-full select-none px-2 pt-3'}>
          <CalloutIcon node={node} />
        </div>
        <div
          {...attributes}
          ref={ref}
          className={`${
            attributes.className ?? ''
          } my-2 flex w-full flex-col rounded border border-solid border-line-divider bg-content-blue-50 py-2 pl-10`}
        >
          {children}
        </div>
      </>
    );
  })
);
