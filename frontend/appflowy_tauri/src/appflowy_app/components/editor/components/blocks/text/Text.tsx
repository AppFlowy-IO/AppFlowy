import React, { forwardRef, memo, useEffect, useState } from 'react';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';
import { EditorElementProps, TextNode } from '$app/application/document/document.types';
import { ReactEditor, useSelected, useSlateStatic } from 'slate-react';
import { useStartIcon } from '$app/components/editor/components/blocks/text/StartIcon.hooks';
import { Editor, Point, Range } from 'slate';

export const Text = memo(
  forwardRef<HTMLDivElement, EditorElementProps<TextNode>>(({ node, children, className, ...attributes }, ref) => {
    const editor = useSlateStatic();
    const { hasStartIcon, renderIcon } = useStartIcon(node);
    const isEmpty = editor.isEmpty(node);
    const selected = useSelected();
    const [isSelectedEmpty, setIsSelectedEmpty] = useState(false);

    const isCollapsed = editor.selection && Range.isCollapsed(editor.selection);

    useEffect(() => {
      const { selection } = editor;

      setIsSelectedEmpty(false);
      if (!selection || !selected || !isEmpty || isCollapsed) return;

      const start = Editor.start(editor, ReactEditor.findPath(editor, node));
      const end = Range.end(selection);

      if (Point.equals(start, end)) {
        setIsSelectedEmpty(true);
      }
    }, [selected, isEmpty, isCollapsed, editor, node]);
    return (
      <span
        ref={ref}
        {...attributes}
        className={`text-element relative my-1 flex w-full whitespace-pre-wrap break-words px-1 ${className ?? ''} ${
          hasStartIcon ? 'has-start-icon' : ''
        }`}
      >
        {renderIcon()}
        <Placeholder isEmpty={isEmpty} node={node} />

        <span className={`text-content ${isSelectedEmpty ? 'selected' : ''}`}>{children}</span>
      </span>
    );
  })
);

export default Text;
