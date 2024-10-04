import Placeholder from '@/components/editor/components/blocks/text/Placeholder';
import { useSlateStatic } from 'slate-react';
import { useStartIcon } from './StartIcon.hooks';
import { EditorElementProps, TextNode } from '@/components/editor/editor.type';
import React, { forwardRef, useMemo } from 'react';

export const Text = forwardRef<HTMLSpanElement, EditorElementProps<TextNode>>(
  ({ node, children, className: classNameProp, ...attributes }, ref) => {
    const { hasStartIcon, renderIcon } = useStartIcon(node);
    const editor = useSlateStatic();
    const isEmpty = editor.isEmpty(node);
    const className = useMemo(() => {
      const classList = ['text-element', 'relative', 'flex', 'w-full', 'whitespace-pre-wrap', 'break-word', 'px-1'];

      if (classNameProp) classList.push(classNameProp);
      if (hasStartIcon) classList.push('has-start-icon');
      return classList.join(' ');
    }, [classNameProp, hasStartIcon]);

    const placeholder = useMemo(() => {
      if (!isEmpty) return null;
      return <Placeholder node={node} />;
    }, [isEmpty, node]);

    const content = useMemo(() => {
      return <>
        {placeholder}
        <span className={`text-content ${isEmpty ? 'empty-text' : ''}`}>{children}</span>
      </>;
    }, [placeholder, isEmpty, children]);

    return (
      <span {...attributes} ref={ref} className={className}>
        {renderIcon()}
        {content}
      </span>
    );
  },
);
