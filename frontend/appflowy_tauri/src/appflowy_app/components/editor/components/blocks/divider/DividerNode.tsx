import React, { forwardRef, memo } from 'react';
import { EditorElementProps, DividerNode as DividerNodeType } from '$app/application/document/document.types';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerNodeType>>(
    ({ node: _node, children: children, ...attributes }, ref) => {
      return (
        <div
          {...attributes}
          ref={ref}
          contentEditable={false}
          className={`${attributes.className ?? ''} relative w-full`}
        >
          <div className={'w-full py-2.5 text-line-divider'}>
            <hr />
          </div>
          <span className={'absolute left-0 top-0 h-0 w-0 opacity-0'}>{children}</span>
        </div>
      );
    }
  )
);
