export function calcToolbarPosition(toolbarDom: HTMLDivElement, blockRect: DOMRect) {
  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    return;
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };

  let top = -toolbarDom.offsetHeight - 5 + (rect.top - blockRect.y);
  let left = rect.left - blockRect.x - toolbarDom.offsetWidth / 2 + rect.width / 2;

  const container = document.querySelector('.doc-scroller-container') as HTMLElement;
  const containerRect = container.getBoundingClientRect();
  const leftThreshold = containerRect.left;
  const rightThreshold = containerRect.left + containerRect.width;

  if (blockRect.x + left < leftThreshold) {
    left = leftThreshold - blockRect.x;
  } else if (blockRect.x + left + toolbarDom.offsetWidth > rightThreshold) {
    left = rightThreshold - blockRect.x - toolbarDom.offsetWidth;
  }

  return {
    top: top + 'px',
    left: left + 'px',
  };
}
