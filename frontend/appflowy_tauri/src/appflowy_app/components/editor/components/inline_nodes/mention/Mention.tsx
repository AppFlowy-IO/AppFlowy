import React, { forwardRef, memo } from 'react';
import { EditorElementProps, MentionNode } from '$app/application/document/document.types';

import MentionLeaf from '$app/components/editor/components/inline_nodes/mention/MentionLeaf';
import { useElementFocused } from '$app/components/editor/components/inline_nodes/useElementFocused';

export const Mention = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<MentionNode>>(({ node, children, ...attributes }, ref) => {
    const focused = useElementFocused(node);

    return (
      <span
        {...attributes}
        data-playwright-selected={focused}
        contentEditable={false}
        className={`${attributes.className ?? ''} text-sx relative rounded px-1 hover:bg-content-blue-100`}
        ref={ref}
        style={{
          backgroundColor: focused ? 'var(--content-blue-100)' : undefined,
        }}
      >
        <MentionLeaf mention={node.data}>{children}</MentionLeaf>
      </span>
    );
  })
);
