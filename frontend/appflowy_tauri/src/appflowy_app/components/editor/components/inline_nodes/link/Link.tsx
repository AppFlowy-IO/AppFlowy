import { memo, useCallback, useRef } from 'react';
import { ReactEditor, useSlate } from 'slate-react';
import { getNodePath } from '$app/components/editor/components/editor/utils';
import { Transforms, Text } from 'slate';
import { useDecorateDispatch } from '$app/components/editor/stores';

export const Link = memo(({ children }: { leaf: Text; children: React.ReactNode }) => {
  const { add: addDecorate } = useDecorateDispatch();

  const editor = useSlate();

  const ref = useRef<HTMLSpanElement | null>(null);

  const handleClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      e.preventDefault();
      if (ref.current === null) {
        return;
      }

      const path = getNodePath(editor, ref.current);

      ReactEditor.focus(editor);
      Transforms.select(editor, path);

      if (!editor.selection) return;
      addDecorate({
        range: editor.selection,
        class_name: 'bg-content-blue-100 rounded',
        type: 'link',
      });
    },
    [addDecorate, editor]
  );

  return (
    <>
      <span
        ref={ref}
        onMouseDown={handleClick}
        className={`cursor-pointer select-auto px-1 py-0.5 text-fill-default underline`}
      >
        {children}
      </span>
    </>
  );
});
