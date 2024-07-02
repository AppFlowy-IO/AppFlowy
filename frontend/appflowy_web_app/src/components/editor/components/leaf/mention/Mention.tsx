import { EditorElementProps, MentionNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo } from 'react';
import { useSelected } from 'slate-react';

import MentionLeaf from './MentionLeaf';

export const Mention = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<MentionNode>>(({ node, children, ...attributes }, ref) => {
    const selected = useSelected();

    return (
      <span
        {...attributes}
        // contentEditable={false}
        className={`mention relative cursor-pointer ${selected ? 'selected' : ''}`}
        ref={ref}
      >
        <span className={'absolute right-0 top-0 h-full w-0 opacity-0'}>{children}</span>
        <MentionLeaf mention={node.data} />
      </span>
    );
  })
);

export default Mention;
