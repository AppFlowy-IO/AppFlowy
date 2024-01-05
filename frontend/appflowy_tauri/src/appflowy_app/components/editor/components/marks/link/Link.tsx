import { memo, useCallback, useEffect, useRef, useState } from 'react';
import { ReactEditor, useSelected, useSlate } from 'slate-react';
import { getNodePath, moveCursorToNodeEnd, moveCursorToPoint } from '$app/components/editor/components/editor/utils';
import { BasePoint, Transforms, Text, Range, Editor } from 'slate';
import { LinkEditPopover } from '$app/components/editor/components/marks/link/LinkEditPopover';

export const Link = memo(({ leaf, children }: { leaf: Text; children: React.ReactNode }) => {
  const nodeSelected = useSelected();

  const editor = useSlate();

  const [selected, setSelected] = useState(false);
  const ref = useRef<HTMLSpanElement | null>(null);
  const [openEditPopover, setOpenEditPopover] = useState<boolean>(false);

  const getSelected = useCallback(
    (el: HTMLSpanElement, selection: Range) => {
      const entry = Editor.node(editor, selection);
      const [node, path] = entry;
      const dom = ReactEditor.toDOMNode(editor, node);

      if (!dom.contains(el)) return false;

      const offset = Editor.string(editor, path).length;
      const range = {
        anchor: {
          path,
          offset: 0,
        },
        focus: {
          path,
          offset,
        },
      };

      return Range.equals(range, selection);
    },
    [editor]
  );

  useEffect(() => {
    if (!ref.current) return;
    const selection = editor.selection;

    if (!nodeSelected || !selection) {
      setOpenEditPopover(false);
      setSelected(false);
      return;
    }

    const selected = getSelected(ref.current, selection);

    setOpenEditPopover(selected);
    setSelected(selected);
  }, [getSelected, editor, nodeSelected]);

  const handleClick = useCallback(() => {
    if (ref.current === null) {
      return;
    }

    const path = getNodePath(editor, ref.current);

    setOpenEditPopover(true);
    setSelected(true);
    ReactEditor.focus(editor);
    Transforms.select(editor, path);
  }, [editor]);

  const handleEditPopoverClose = useCallback(
    (at?: BasePoint) => {
      setOpenEditPopover(false);
      setSelected(false);
      if (ref.current === null) {
        return;
      }

      if (!at) {
        moveCursorToNodeEnd(editor, ref.current);
      } else {
        moveCursorToPoint(editor, at);
      }
    },
    [editor]
  );

  return (
    <>
      <span
        ref={ref}
        onClick={handleClick}
        className={`rounded px-1 py-0.5 text-fill-default underline ${selected ? 'bg-content-blue-50' : ''}`}
      >
        {children}
      </span>
      {openEditPopover && (
        <LinkEditPopover
          open={openEditPopover}
          anchorEl={ref.current}
          onClose={handleEditPopoverClose}
          defaultHref={leaf.href || ''}
        />
      )}
    </>
  );
});
