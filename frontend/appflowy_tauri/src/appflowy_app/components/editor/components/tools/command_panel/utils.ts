import { ReactEditor } from 'slate-react';

export function getPanelPosition(editor: ReactEditor) {
  const { selection } = editor;

  const isFocused = ReactEditor.isFocused(editor);

  if (!selection || !isFocused) {
    return null;
  }

  const domSelection = window.getSelection();
  const rangeCount = domSelection?.rangeCount;

  if (!rangeCount) return null;

  const domRange = rangeCount > 0 ? domSelection.getRangeAt(0) : undefined;

  const rect = domRange?.getBoundingClientRect();

  if (!rect) return null;
  const nodeDom = domSelection.anchorNode?.parentElement?.closest('.text-element');
  const height = (nodeDom?.getBoundingClientRect().height ?? 0) + 8;

  return {
    ...rect,
    height,
    top: rect.top,
    left: rect.left,
  };
}
