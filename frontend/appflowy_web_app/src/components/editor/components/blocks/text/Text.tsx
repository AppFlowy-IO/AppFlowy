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
      const className = useMemo(() => {
        const classList = ['text-element', 'relative', 'flex', 'w-full', 'whitespace-pre-wrap', 'break-all', 'px-1'];

        if (classNameProp) classList.push(classNameProp);
        if (hasStartIcon) classList.push('has-start-icon');
        return classList.join(' ');
      }, [classNameProp, hasStartIcon]);

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
