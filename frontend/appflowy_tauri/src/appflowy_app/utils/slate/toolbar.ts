import { Editor, Range } from 'slate';
import { BlockPosition } from '../../block_editor/position';
export function calcToolbarPosition(editor: Editor, toolbarDom: HTMLDivElement, blockPosition: BlockPosition) {
  const { selection } = editor;

  const scrollContainer = document.querySelector('.doc-scroller-container');
  if (!scrollContainer) return;

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
  
  const top = `${-toolbarDom.offsetHeight - 5 + (rect.top + scrollContainer.scrollTop - blockPosition.y)}px`;
  const left = `${rect.left - blockPosition.x - toolbarDom.offsetWidth / 2 + rect.width / 2}px`;
  
  return {
    top,
    left,
  }
  
}
