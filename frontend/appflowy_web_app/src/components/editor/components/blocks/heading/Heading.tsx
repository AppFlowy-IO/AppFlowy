import { HEADER_HEIGHT } from '@/application/constants';
import { EditorElementProps, HeadingNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

export const Heading = memo(
  forwardRef<HTMLDivElement, EditorElementProps<HeadingNode>>(({ node, children, ...attributes }, ref) => {
    const level = node.data.level;

    const className = `${attributes.className ?? ''} heading level-${level}`;

    return (
      <div
        {...attributes}
        ref={ref}
        id={`heading-${node.blockId}`}
        style={{
          scrollMarginTop: HEADER_HEIGHT,
          ...attributes.style,
        }}
        className={className}
      >
        {children}
      </div>
    );
  }),
);

export default Heading;
