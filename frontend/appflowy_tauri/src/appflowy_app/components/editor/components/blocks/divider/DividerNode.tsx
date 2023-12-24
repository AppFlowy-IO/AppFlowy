import React, { forwardRef, memo } from 'react';
import { EditorElementProps, DividerNode as DividerNodeType } from '$app/application/document/document.types';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerNodeType>>(
    ({ node: _node, children: children, ...attributes }, ref) => {
      return (
        <>
          <div contentEditable={false} className={'absolute w-full py-2.5 text-line-divider'}>
            <hr />
          </div>
          <div {...attributes} ref={ref} className={`${attributes.className ?? ''} caret-transparent`}>
            <span className={'h-6 w-full'}>{children}</span>
          </div>
        </>
      );
    }
  )
);
