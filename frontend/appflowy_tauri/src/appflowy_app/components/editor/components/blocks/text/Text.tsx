import React, { forwardRef, memo } from 'react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { EditorElementProps, TextNode } from '$app/application/document/document.types';
import { useSlateStatic } from 'slate-react';

export const Text = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TextNode>>(({ node, children, ...attributes }, ref) => {
    const editor = useSlateStatic();
    const isEmpty = editor.isEmpty(node);

    return (
      <div ref={ref} {...attributes} className={`text-element mx-1 ${!isEmpty ? 'flex' : ''} relative h-full`}>
        <Placeholder isEmpty={isEmpty} node={node} />
        <span>{children}</span>
      </div>
    );
  })
);

export default Text;
