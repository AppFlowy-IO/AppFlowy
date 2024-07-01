import { HEADER_HEIGHT } from '@/components/publish/header';
import { getHeadingCssProperty } from './utils';
import { EditorElementProps, HeadingNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

export const Heading = memo(
  forwardRef<HTMLDivElement, EditorElementProps<HeadingNode>>(({ node, children, ...attributes }, ref) => {
    const level = node.data.level;
    const fontSizeCssProperty = getHeadingCssProperty(level);

    const className = `${attributes.className ?? ''} ${fontSizeCssProperty} level-${level}`;

    return (
      <div
        {...attributes}
        ref={ref}
        id={`heading-${node.blockId}`}
        style={{
          scrollMarginTop: HEADER_HEIGHT,
        }}
        className={className}
      >
        {children}
      </div>
    );
  })
);

export default Heading;
