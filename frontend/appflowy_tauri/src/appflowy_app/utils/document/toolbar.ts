export function calcToolbarPosition(toolbarDom: HTMLDivElement) {
  const domSelection = window.getSelection();
  let domRange;
  if (domSelection?.rangeCount === 0) {
    return;
  } else {
    domRange = domSelection?.getRangeAt(0);
  }

  const rect = domRange?.getBoundingClientRect() || { top: 0, left: 0, width: 0, height: 0 };

  let top = rect.top - toolbarDom.offsetHeight;
  let left = rect.left - toolbarDom.offsetWidth / 2 + rect.width / 2;

  return {
    top: top + 'px',
    left: left + 'px',
  };
}
