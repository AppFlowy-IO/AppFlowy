import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, NumberedListNode } from '$app/application/document/document.types';

import { ReactEditor, useSlateStatic } from 'slate-react';
import { Editor, Element } from 'slate';
import Placeholder from '$app/components/editor/components/blocks/_shared/Placeholder';

export const NumberedList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<NumberedListNode>>(({ node, children, ...attributes }, ref) => {
    const editor = useSlateStatic();

    const index = useMemo(() => {
      let index = 1;
      const path = ReactEditor.findPath(editor, node);

      let prevEntry = Editor.previous(editor, {
        at: path,
      });

      while (prevEntry) {
        const prevNode = prevEntry[0];

        if (Element.isElement(prevNode) && !Editor.isEditor(prevNode)) {
          if (prevNode.type === node.type && prevNode.level === node.level) {
            index += 1;
          } else {
            break;
          }
        }

        prevEntry = Editor.previous(editor, {
          at: prevEntry[1],
        });
      }

      return index;
    }, [editor, node]);

    return (
      <div {...attributes} className={`${attributes.className ?? ''} relative`} ref={ref}>
        <span contentEditable={false} className={'pr-2 font-medium'}>
          {index}.
        </span>
        <span className={'relative'}>
          <Placeholder node={node} />
          {children}
        </span>
      </div>
    );
  })
);
