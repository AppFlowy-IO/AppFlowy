import { EditorElementProps, MentionNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';

import MentionLeaf from './MentionLeaf';

export const Mention = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<MentionNode>>(({ node, children, ...attributes }, ref) => {
    return (
      <span {...attributes} contentEditable={false} className={`relative cursor-pointer`} ref={ref}>
        <span className={'absolute right-0 top-0 h-full w-0 opacity-0'}>{children}</span>
        <MentionLeaf mention={node.data} />
      </span>
    );
  })
);

export default Mention;
