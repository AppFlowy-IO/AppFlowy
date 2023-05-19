export function isPointInBlock(target: HTMLElement | null) {
  let node = target;
  while (node) {
    if (node.getAttribute('data-block-id')) {
      return true;
    }
    node = node.parentElement;
  }
  return false;
}

export function getBlockIdByPoint(target: HTMLElement | null) {
  let node = target;
  while (node) {
    const id = node.getAttribute('data-block-id');
    if (id) {
      return id;
    }
    node = node.parentElement;
  }
  return null;
}
