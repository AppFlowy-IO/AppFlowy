import { ReactEditor } from 'slate-react';

export function getRangeRect () {
  const domSelection = window.getSelection();
  const rangeCount = domSelection?.rangeCount;

  if (!rangeCount) return null;

  const anchorNode = domSelection.anchorNode;
  const focusNode = domSelection.focusNode;
  const focusOffset = domSelection.focusOffset;
  let domRange = rangeCount > 0 ? domSelection.getRangeAt(0) : undefined;

  const anchorTop = anchorNode?.parentElement?.getBoundingClientRect().top;
  const focusTop = focusNode?.parentElement?.getBoundingClientRect().top;
  const diff = Math.abs((anchorTop || 0) - (focusTop || 0));

  if (focusNode && anchorNode && diff > 20) {
    const newRange = document.createRange();

    newRange.setStart(focusNode, focusOffset);

    domRange = newRange;
  }

  return domRange?.getBoundingClientRect();
}

export function getSelectionPosition (editor: ReactEditor) {

  const rect = getRangeRect();

  if (!rect) return null;
  let newRect;

  const domNode = ReactEditor.toDOMNode(editor, editor);
  const domNodeRect = domNode.getBoundingClientRect();

  // the default height of the toolbar is 30px
  const gap = 78;

  if (rect) {
    let relativeDomTop = rect.top - domNodeRect.top;
    const relativeDomLeft = rect.left - domNodeRect.left;

    // if the range is above the window, move the toolbar to the bottom of range
    if (rect.top < gap) {
      relativeDomTop = -domNodeRect.top + gap;
    }

    newRect = {
      top: relativeDomTop,
      left: relativeDomLeft,
      width: rect.width,
      height: rect.height,
    };
  }

  return newRect;
}

