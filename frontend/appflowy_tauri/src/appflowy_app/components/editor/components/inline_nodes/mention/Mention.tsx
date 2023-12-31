import React, { forwardRef, memo } from 'react';
import { EditorElementProps, MentionNode } from '$app/application/document/document.types';

import MentionLeaf from '$app/components/editor/components/inline_nodes/mention/MentionLeaf';

export const Mention = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<MentionNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <>
        <span {...attributes} contentEditable={false} ref={ref}>
          <MentionLeaf mention={node.data}>{children}</MentionLeaf>
        </span>
      </>
    );
  })
);
