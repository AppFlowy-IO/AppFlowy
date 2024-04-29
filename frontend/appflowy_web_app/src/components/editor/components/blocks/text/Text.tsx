import Placeholder from '@/components/editor/components/blocks/text/Placeholder';
import { useSlateStatic } from 'slate-react';
import { useStartIcon } from './StartIcon.hooks';
import { EditorElementProps, TextNode } from '@/components/editor/editor.type';

import React, { forwardRef, memo, useMemo } from 'react';

export const Text = memo(
  forwardRef<HTMLSpanElement, EditorElementProps<TextNode>>(
    ({ node, children, className: classNameProp, ...attributes }, ref) => {
      const { hasStartIcon, renderIcon } = useStartIcon(node);
      const editor = useSlateStatic();
      const isEmpty = editor.isEmpty(node);
      const className = useMemo(
        () =>
          `text-element relative my-1 flex w-full whitespace-pre-wrap break-words px-1 ${classNameProp ?? ''} ${
            hasStartIcon ? 'has-start-icon' : ''
          }`,
        [classNameProp, hasStartIcon]
      );

      return (
        <span {...attributes} ref={ref} className={className}>
          {renderIcon()}
          {isEmpty && <Placeholder node={node} />}
          <span className={`text-content ${isEmpty ? 'empty-text' : ''}`}>{children}</span>
        </span>
      );
    }
  )
);
