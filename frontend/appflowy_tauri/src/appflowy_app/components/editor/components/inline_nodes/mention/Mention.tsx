import React, { forwardRef, memo } from 'react';
import { EditorElementProps, MentionNode } from '$app/application/document/document.types';

import MentionLeaf from '$app/components/editor/components/inline_nodes/mention/MentionLeaf';
import { InlineChromiumBugfix } from '$app/components/editor/components/inline_nodes/InlineChromiumBugfix';

export const Mention = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<MentionNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <span {...attributes} contentEditable={false} className={`relative cursor-pointer`} ref={ref}>
        <InlineChromiumBugfix className={'left-0'} />
        <span className={'absolute right-0 top-0 h-full w-0 opacity-0'}>{children}</span>
        <MentionLeaf mention={node.data} />
        <InlineChromiumBugfix className={'right-0'} />
      </span>
    );
  })
);
