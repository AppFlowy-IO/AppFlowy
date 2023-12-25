import React, { forwardRef, memo } from 'react';
import { EditorElementProps, DividerNode as DividerNodeType } from '$app/application/document/document.types';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerNodeType>>(
    ({ node: _node, children: children, className, ...attributes }, ref) => {
      return (
        <div {...attributes} className={`${className} relative`}>
          <div contentEditable={false} className={'w-full py-2.5 text-line-divider'}>
            <hr />
          </div>
          <div ref={ref} className={`absolute h-full w-full caret-transparent`}>
            {children}
          </div>
        </div>
      );
    }
  )
);
