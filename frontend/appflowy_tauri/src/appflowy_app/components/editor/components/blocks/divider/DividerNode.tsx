import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, DividerNode as DividerNodeType } from '$app/application/document/document.types';
import { useSelected } from 'slate-react';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerNodeType>>(
    ({ node: _node, children: children, ...attributes }, ref) => {
      const selected = useSelected();

      const className = useMemo(() => {
        return `${attributes.className ?? ''} divider-node relative w-full rounded ${
          selected ? 'bg-content-blue-100' : ''
        }`;
      }, [attributes.className, selected]);

      return (
        <div {...attributes} className={className}>
          <div contentEditable={false} className={'w-full px-1 py-2 text-line-divider'}>
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
