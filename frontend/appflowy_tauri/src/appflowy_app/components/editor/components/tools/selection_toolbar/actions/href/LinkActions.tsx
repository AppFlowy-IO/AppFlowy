import React, { useCallback, useMemo } from 'react';
import { useDecorateDispatch, useDecorateState } from '$app/components/editor/stores';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { Editor } from 'slate';
import { LinkEditPopover } from '$app/components/editor/components/inline_nodes/link';

export function LinkActions() {
  const editor = useSlateStatic();
  const decorateState = useDecorateState('link');
  const openEditPopover = !!decorateState;
  const { clear: clearDecorate } = useDecorateDispatch();

  const anchorPosition = useMemo(() => {
    const range = decorateState?.range;

    if (!range) return;

    const domRange = ReactEditor.toDOMRange(editor, range);

    const rect = domRange.getBoundingClientRect();

    return {
      top: rect.top,
      left: rect.left,
      height: rect.height,
    };
  }, [decorateState?.range, editor]);

  const defaultHref = useMemo(() => {
    const range = decorateState?.range;

    if (!range) return '';

    const marks = Editor.marks(editor);

    return marks?.href || Editor.string(editor, range);
  }, [decorateState?.range, editor]);

  const handleEditPopoverClose = useCallback(() => {
    const range = decorateState?.range;

    clearDecorate();
    if (range) {
      ReactEditor.focus(editor);
      editor.select(range);
    }
  }, [clearDecorate, decorateState?.range, editor]);

  if (!openEditPopover) return null;
  return (
    <LinkEditPopover
      open={openEditPopover}
      anchorPosition={anchorPosition}
      anchorReference={'anchorPosition'}
      onClose={handleEditPopoverClose}
      defaultHref={defaultHref}
    />
  );
}
