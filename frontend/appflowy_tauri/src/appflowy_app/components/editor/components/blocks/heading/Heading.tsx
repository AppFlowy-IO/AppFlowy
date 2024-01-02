import React, { forwardRef, memo } from 'react';
import { EditorElementProps, HeadingNode } from '$app/application/document/document.types';
import { getHeadingCssProperty } from '$app/components/editor/plugins/utils';

export const Heading = memo(
  forwardRef<HTMLDivElement, EditorElementProps<HeadingNode>>(({ node, children, ...attributes }, ref) => {
    const level = node.data.level;
    const fontSizeCssProperty = getHeadingCssProperty(level);

    const className = `${attributes.className ?? ''} ${fontSizeCssProperty}`;

    return (
      <div {...attributes} ref={ref} className={className}>
        {children}
      </div>
    );
  })
);
