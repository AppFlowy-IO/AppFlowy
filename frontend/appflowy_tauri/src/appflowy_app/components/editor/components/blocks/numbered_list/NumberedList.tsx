import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, NumberedListNode } from '$app/application/document/document.types';

import { ReactEditor, useSlate } from 'slate-react';
import { Element, Path } from 'slate';

export const NumberedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<NumberedListNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const editor = useSlate();

      const path = ReactEditor.findPath(editor, node);
      const index = useMemo(() => {
        let index = 1;

        let prevPath = Path.previous(path);

        while (prevPath) {
          const prev = editor.node(prevPath);

          const prevNode = prev[0] as Element;

          if (prevNode.type === node.type) {
            index += 1;
          } else {
            break;
          }

          prevPath = Path.previous(prevPath);
        }

        return index;
      }, [editor, node, path]);

      return (
        <>
          <span contentEditable={false} className={'absolute flex w-6 select-none justify-center font-medium'}>
            {index}.
          </span>
          <div ref={ref} {...attributes} className={`${className} ml-6`}>
            {children}
          </div>
        </>
      );
    }
  )
);
