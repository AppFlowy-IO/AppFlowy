import React, { forwardRef, memo } from 'react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { EditorElementProps, TextNode } from '$app/application/document/document.types';
import { useSlateStatic } from 'slate-react';

export const Text = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TextNode>>(({ node, children, className, ...attributes }, ref) => {
    const editor = useSlateStatic();
    const isEmpty = editor.isEmpty(node);

    return (
      <div
        ref={ref}
        {...attributes}
        className={`text-element min-h-[26px] px-1 ${!isEmpty ? 'flex items-center' : 'select-none leading-[26px]'} ${
          className ?? ''
        } relative h-full`}
      >
        <Placeholder isEmpty={isEmpty} node={node} />
        <span>{children}</span>
      </div>
    );
  })
);

export default Text;
