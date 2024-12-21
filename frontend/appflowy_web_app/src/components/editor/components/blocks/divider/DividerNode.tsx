import { EditorElementProps, DividerNode as DividerBlock } from '@/components/editor/editor.type';
import React, { forwardRef, memo, useMemo } from 'react';
import { useReadOnly, useSlateStatic } from 'slate-react';
import { Element } from 'slate';

export const DividerNode = memo(
  forwardRef<HTMLDivElement, EditorElementProps<DividerBlock>>(
    ({ node: node, children: children, ...attributes }, ref) => {
      const editor = useSlateStatic();
      const readOnly = useReadOnly() || editor.isElementReadOnly(node as unknown as Element);

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
            className={'w-full py-2'}
          >
            <hr className={'border-line-border'}/>
          </div>
          <div
            className={`absolute opacity-0 h-full w-full caret-transparent`}
          >
            {children}
          </div>
        </div>
      );
    },
  ),
);

export default DividerNode;
