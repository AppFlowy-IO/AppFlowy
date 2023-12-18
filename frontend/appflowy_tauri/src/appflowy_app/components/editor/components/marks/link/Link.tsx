import { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ReactEditor, useSelected, useSlate } from 'slate-react';
import { getNodePath, moveCursorToNodeEnd, moveCursorToPoint } from '$app/components/editor/components/editor/utils';
import { BasePoint, Transforms, Text, Range, Point } from 'slate';
import { LinkEditPopover } from '$app/components/editor/components/marks/link/LinkEditPopover';

export const Link = memo(({ leaf, children }: { leaf: Text; children: React.ReactNode }) => {
  const nodeSelected = useSelected();

  const editor = useSlate();

  const ref = useRef<HTMLSpanElement | null>(null);
  const [openEditPopover, setOpenEditPopover] = useState<boolean>(false);

  const selected = useMemo(() => {
    if (!editor.selection || !nodeSelected || !ref.current) return false;

    const node = ReactEditor.toSlateNode(editor, ref.current);
    const path = ReactEditor.findPath(editor, node);
    const range = { anchor: { path, offset: 0 }, focus: { path, offset: leaf.text.length } };
    const isContained = Range.includes(range, editor.selection);
    const selectionIsCollapsed = Range.isCollapsed(editor.selection);
    const point = Range.start(editor.selection);

    if ((selectionIsCollapsed && point && Point.equals(point, range.focus)) || Point.equals(point, range.anchor)) {
      return false;
    }

    return isContained;
  }, [editor, nodeSelected, leaf.text.length]);

  useEffect(() => {
    if (selected) {
      setOpenEditPopover(true);
    } else {
      setOpenEditPopover(false);
    }
  }, [selected]);

  const handleClick = useCallback(() => {
    if (ref.current === null) {
      return;
    }

    const path = getNodePath(editor, ref.current);

    setOpenEditPopover(true);
    ReactEditor.focus(editor);
    Transforms.select(editor, path);
  }, [editor]);

  const handleEditPopoverClose = useCallback(
    (at?: BasePoint) => {
      setOpenEditPopover(false);
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
