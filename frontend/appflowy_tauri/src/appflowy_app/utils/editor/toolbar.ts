import { Editor, Range } from 'slate';
export function calcToolbarPosition(editor: Editor, el: HTMLDivElement, blockRect: DOMRect) {
  const { selection } = editor;

  if (!selection || Range.isCollapsed(selection) || Editor.string(editor, selection) === '') {
    return;
  }

  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    domRange = document.createRange();
    domRange.setStart(el, domSelection?.anchorOffset);
    domRange.setEnd(el, domSelection?.anchorOffset);
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };
  
  const top = `${-el.offsetHeight - 5}px`;
  const left = `${rect.left - blockRect.left - el.offsetWidth / 2 + rect.width / 2}px`;
  return {
    top,
    left,
  }
  
}
