import { getBlockEditor } from '@/appflowy_app/block_editor';
import { Editor, Range } from 'slate';
export function calcToolbarPosition(editor: Editor, toolbarDom: HTMLDivElement, blockId: string) {
  const { selection } = editor;

  const scrollContainer = document.querySelector('.doc-scroller-container');
  if (!scrollContainer) return;

  if (!selection || Range.isCollapsed(selection) || Editor.string(editor, selection) === '') {
    return;
  }

  const blockEditor = getBlockEditor();
  const blockRect = blockEditor?.renderTree.getNodeRect(blockId);
  const blockDom = document.querySelector(`[data-block-id=${blockId}]`);

  if (!blockDom || !blockRect) return;

  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    return;
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };
  
  const top = `${-toolbarDom.offsetHeight - 5 + (rect.top + scrollContainer.scrollTop - blockRect.top)}px`;
  const left = `${rect.left - blockRect.left - toolbarDom.offsetWidth / 2 + rect.width / 2}px`;
  
  return {
    top,
    left,
  }
  
}
