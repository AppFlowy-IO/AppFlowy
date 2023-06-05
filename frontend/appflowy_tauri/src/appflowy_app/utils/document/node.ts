function isTextNode(node: Node): boolean {
  return node.nodeType === Node.TEXT_NODE;
}

export function exclude(node: Element) {
  let isPlaceholder = false;
  try {
    isPlaceholder = !!node.getAttribute('data-slate-placeholder');
  } catch (e) {
    // ignore
  }
  return isPlaceholder;
}

function findFirstTextNode(node: Node): Node | null {
  if (isTextNode(node)) {
    return node;
  }
  if (exclude && exclude(node as Element)) {
    return null;
  }

  const children = node.childNodes;
  for (let i = 0; i < children.length; i++) {
    const textNode = findFirstTextNode(children[i]);
    if (textNode) {
      return textNode;
    }
  }

  return null;
}

export function setCursorAtStartOfNode(node: Node): void {
  const range = document.createRange();
  const textNode = findFirstTextNode(node);

  if (textNode) {
    range.setStart(textNode, 0);
    range.collapse(true); // 将选区折叠到起始位置
  }

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

function findLastTextNode(node: Node): Node | null {
  if (isTextNode(node)) {
    return node;
  }

  if (exclude && exclude(node as Element)) {
    return null;
  }

  const children = node.childNodes;
  for (let i = children.length - 1; i >= 0; i--) {
    const textNode = findLastTextNode(children[i]);
    if (textNode) {
      return textNode;
    }
  }

  return null;
}

export function setCursorAtEndOfNode(node: Node): void {
  const range = document.createRange();
  const textNode = findLastTextNode(node);

  if (textNode) {
    const textLength = textNode.textContent?.length || 0;
    range.setStart(textNode, textLength);
    range.setEnd(textNode, textLength);
  }

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

export function setFullRangeAtNode(node: Node): void {
  const range = document.createRange();
  const firstTextNode = findFirstTextNode(node);
  const lastTextNode = findLastTextNode(node);
  if (!firstTextNode || !lastTextNode) return;
  range.setStart(firstTextNode, 0);
  range.setEnd(lastTextNode, lastTextNode.textContent?.length || 0);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
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

export function findTextBoxParent(target: HTMLElement | null) {
  let node = target;
  while (node) {
    if (node.getAttribute('role') === 'textbox') {
      return node;
    }
    node = node.parentElement;
  }
  return null;
}

export function isFocused(blockId: string) {
  const selection = window.getSelection();
  if (!selection) return false;
  const { anchorNode, focusNode } = selection;
  if (!anchorNode || !focusNode) return false;
  const anchorElement = anchorNode.parentElement;
  const focusElement = focusNode.parentElement;
  if (!anchorElement || !focusElement) return false;
  const anchorBlockId = getBlockIdByPoint(anchorElement);
  const focusBlockId = getBlockIdByPoint(focusElement);
  return anchorBlockId === blockId || focusBlockId === blockId;
}

export function getNode(id: string) {
  return document.querySelector(`[data-block-id="${id}"]`);
}

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

export function findTextNode(
  node: Element,
  index: number
): {
  node?: Node;
  offset?: number;
  remainingIndex?: number;
} {
  if (isTextNode(node)) {
    const textLength = node.textContent?.length || 0;
    if (index <= textLength) {
      return { node, offset: index };
    }
    return { remainingIndex: index - textLength };
  }

  if (exclude && exclude(node)) {
    return { remainingIndex: index };
  }
  let remainingIndex = index;
  for (const childNode of node.childNodes) {
    const result = findTextNode(childNode as Element, remainingIndex);
    if (result.node) {
      return result;
    }
    remainingIndex = result.remainingIndex || index;
  }

  return { remainingIndex };
}

export function focusNodeByIndex(node: Element, index: number, length: number) {
  const textBoxNode = node.querySelector(`[role="textbox"]`);
  if (!textBoxNode) return;
  const anchorNode = findTextNode(textBoxNode, index);
  const focusNode = findTextNode(textBoxNode, index + length);

  if (!anchorNode?.node || !focusNode?.node) return;

  const range = document.createRange();
  range.setStart(anchorNode.node, anchorNode.offset || 0);
  range.setEnd(focusNode.node, focusNode.offset || 0);

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

export function getNodeTextBoxByBlockId(blockId: string) {
  const node = getNode(blockId);
  return node?.querySelector(`[role="textbox"]`);
}

export function getNodeText(node: Element) {
  if (isTextNode(node)) {
    return node.textContent || '';
  }
  if (exclude && exclude(node)) {
    return '';
  }
  let text = '';
  for (const childNode of node.childNodes) {
    text += getNodeText(childNode as Element);
  }
  return replaceZeroWidthSpace(text);
}

export function replaceZeroWidthSpace(text: string) {
  // Unicode has the following characters that are invisible and have no width:
  // \u200B - zero width space
  // \u200C - zero width non-joiner
  // \u200D - zero width joiner
  // \uFEFF - zero width no-break space
  return text.replace(/[\u200B-\u200D\uFEFF]/g, '');
}

export function findParent(node: Element, parentSelector: string) {
  let parentNode: Element | null = node;
  while (parentNode) {
    if (parentNode.matches(parentSelector)) {
      return parentNode;
    }
    parentNode = parentNode.parentElement;
  }
  return null;
}
