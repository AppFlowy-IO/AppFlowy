export function calcToolbarPosition(toolbarDom: HTMLDivElement, node: Element, container: HTMLDivElement) {
  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    return;
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const nodeRect = node.getBoundingClientRect();
  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };

  const top = rect.top - nodeRect.top - toolbarDom.offsetHeight;
  let left = rect.left - nodeRect.left - toolbarDom.offsetWidth / 2 + rect.width / 2;

  // fix toolbar position when it is out of the container
  const containerRect = container.getBoundingClientRect();
  const leftBound = containerRect.left - nodeRect.left;
  const rightBound = containerRect.right;

  const rightThreshold = 20;
  if (left < leftBound) {
    left = leftBound;
  } else if (left + nodeRect.left + toolbarDom.offsetWidth > rightBound) {
    left = rightBound - toolbarDom.offsetWidth - nodeRect.left - rightThreshold;
  }


  return {
    top,
    left,
  };
}
