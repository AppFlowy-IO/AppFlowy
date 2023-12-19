import React, { forwardRef, memo } from 'react';
import { EditorElementProps, HeadingNode } from '$app/application/document/document.types';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { getHeadingCssProperty } from '$app/components/editor/plugins/utils';

export const Heading = memo(
  forwardRef<HTMLDivElement, EditorElementProps<HeadingNode>>(({ node, children, ...attributes }, ref) => {
    const { data } = node;
    const { level } = data;
    const fontSizeCssProperty = getHeadingCssProperty(level);

    return (
      <div
        {...attributes}
        ref={ref}
        className={`${attributes.className ?? ''} leading-1 relative font-bold ${fontSizeCssProperty}`}
      >
        <Placeholder node={node} className={fontSizeCssProperty} />
        {children}
      </div>
    );
  })
);
