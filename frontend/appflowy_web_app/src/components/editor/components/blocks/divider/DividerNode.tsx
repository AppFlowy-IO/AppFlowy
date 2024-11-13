import { EditorElementProps, DividerNode as DividerBlock } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';
import { useReadOnly } from 'slate-react';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerBlock>>(
    ({ node: _node, children: children, ...attributes }, ref) => {
      const readOnly = useReadOnly();
      const className = useMemo(() => {
        return `${attributes.className ?? ''} divider-node relative w-full rounded`;
      }, [attributes.className]);

      return (
        <div
          {...attributes}
          contentEditable={readOnly ? false : undefined}
          ref={ref}
          className={className}
        >
          <div
            contentEditable={false}
            className={'w-full px-1 py-2'}
          >
            <hr className={'border-line-border'} />
          </div>
          <div
            className={`absolute h-full w-full caret-transparent`}
          >
            {children}
          </div>
        </div>
      );
    },
  ),
);

export default DividerNode;
