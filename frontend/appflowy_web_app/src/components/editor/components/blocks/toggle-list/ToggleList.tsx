import { getHeadingCssProperty } from '@/components/editor/components/blocks/heading';
import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '@/components/editor/editor.type';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed, level } = useMemo(() => node.data || {}, [node.data]);
    const fontSizeCssProperty = getHeadingCssProperty(level || 0);
    const className = `${attributes.className ?? ''} flex w-full flex-col ${collapsed ? 'collapsed' : ''} ${fontSizeCssProperty} level-${level}`;

    return (
      <>
        <div {...attributes} ref={ref}
             className={className}
        >
          {children}
        </div>
      </>
    );
  }),
);

export default ToggleList;
