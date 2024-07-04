import { EditorElementProps, CalloutNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';
import CalloutIcon from './CalloutIcon';

export const Callout = memo(
  forwardRef<HTMLDivElement, EditorElementProps<CalloutNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <>
        <div contentEditable={false} className={'absolute w-full select-none px-2 pt-[15px]'}>
          <CalloutIcon node={node} />
        </div>
        <div ref={ref} className={`${attributes.className ?? ''} w-full bg-bg-body py-2`}>
          <div
            {...attributes}
            className={`flex w-full flex-col rounded border border-line-divider bg-fill-list-active py-2 pl-10`}
          >
            {children}
          </div>
        </div>
      </>
    );
  })
);

export default Callout;
