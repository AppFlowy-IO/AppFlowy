import { ReactEditor } from 'slate-react';
import { getEditorDomNode, getHeadingCssProperty } from '$app/components/editor/plugins/utils';
import { Element } from 'slate';
import { EditorNodeType, HeadingNode } from '$app/application/document/document.types';

export function getBlockActionsPosition(editor: ReactEditor, blockElement: HTMLElement) {
  const editorDom = getEditorDomNode(editor);
  const editorDomRect = editorDom.getBoundingClientRect();
  const blockDomRect = blockElement.getBoundingClientRect();

  const relativeTop = blockDomRect.top - editorDomRect.top;
  const relativeLeft = blockDomRect.left - editorDomRect.left;

  return {
    top: relativeTop,
    left: relativeLeft,
  };
}

export function getBlockCssProperty(node: Element) {
  switch (node.type) {
    case EditorNodeType.HeadingBlock:
      return `${getHeadingCssProperty((node as HeadingNode).data.level)} mt-1`;
    case EditorNodeType.CodeBlock:
    case EditorNodeType.CalloutBlock:
    case EditorNodeType.EquationBlock:
    case EditorNodeType.GridBlock:
      return 'my-3';
    case EditorNodeType.DividerBlock:
      return 'my-0';
    default:
      return 'mt-1';
  }
}

/**
 * Resolve can not find the range when the drop occurs on the icon.
 * @param editor
 * @param e
 */
export function findEventRange(editor: ReactEditor, e: MouseEvent) {
  const { clientX: x, clientY: y } = e;

  // Else resolve a range from the caret position where the drop occured.
  let domRange;
  const { document } = ReactEditor.getWindow(editor);

  // COMPAT: In Firefox, `caretRangeFromPoint` doesn't exist. (2016/07/25)
  if (document.caretRangeFromPoint) {
    domRange = document.caretRangeFromPoint(x, y);
  } else if ('caretPositionFromPoint' in document && typeof document.caretPositionFromPoint === 'function') {
    const position = document.caretPositionFromPoint(x, y);

    if (position) {
      domRange = document.createRange();
      domRange.setStart(position.offsetNode, position.offset);
      domRange.setEnd(position.offsetNode, position.offset);
    }
  }

  if (domRange && domRange.startContainer) {
    const startContainer = domRange.startContainer;

    let element: HTMLElement | null = startContainer as HTMLElement;
    const nodeType = element.nodeType;

    if (nodeType === 3 || typeof element === 'string') {
      const parent = element.parentElement?.closest('.text-block-icon') as HTMLElement;

      element = parent;
    }

    if (element && element.nodeType < 3) {
      if (element.classList?.contains('text-block-icon')) {
        const sibling = domRange.startContainer.parentElement;

        if (sibling) {
          domRange.selectNode(sibling);
        }
      }
    }
  }

  if (!domRange) {
    return null;
  }

  try {
    return ReactEditor.toSlateRange(editor, domRange, {
      exactMatch: false,
      suppressThrow: false,
    });
  } catch {
    return null;
  }
}
