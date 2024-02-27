import React, { useMemo } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { Element, Path } from 'slate';
import { NumberedListNode } from '$app/application/document/document.types';

function NumberListIcon({ block, className }: { block: NumberedListNode; className: string }) {
  const editor = useSlate();

  const path = ReactEditor.findPath(editor, block);
  const index = useMemo(() => {
    let index = 1;

    let prevPath = Path.previous(path);

    while (prevPath) {
      const prev = editor.node(prevPath);

      const prevNode = prev[0] as Element;

      if (prevNode.type === block.type) {
        index += 1;
      } else {
        break;
      }

      prevPath = Path.previous(prevPath);
    }

    return index;
  }, [editor, block, path]);

  return (
    <span
      onMouseDown={(e) => {
        e.preventDefault();
      }}
      contentEditable={false}
      data-number={index}
      className={`${className} numbered-icon flex w-[23px] justify-center pr-1 font-medium`}
    />
  );
}

export default NumberListIcon;
