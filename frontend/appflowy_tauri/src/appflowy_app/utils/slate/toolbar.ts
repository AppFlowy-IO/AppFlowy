import { Editor, Range } from 'slate';
export function calcToolbarPosition(editor: Editor, toolbarDom: HTMLDivElement, blockRect: DOMRect) {
  const { selection } = editor;

  if (!selection || Range.isCollapsed(selection) || Editor.string(editor, selection) === '') {
    return;
  }

  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    return;
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };
  
  const top = `${-toolbarDom.offsetHeight - 5 + (rect.top - blockRect.y)}px`;
  const left = `${rect.left - blockRect.x - toolbarDom.offsetWidth / 2 + rect.width / 2}px`;
  
  return {
    top,
    left,
  }
  
}
