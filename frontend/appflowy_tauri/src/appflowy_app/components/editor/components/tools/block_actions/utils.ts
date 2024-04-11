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
 * @param editor
 * @param e
 */
export function findEventNode(
  editor: ReactEditor,
  {
    x,
    y,
  }: {
    x: number;
    y: number;
  }
) {
  const element = document.elementFromPoint(x, y);
  const nodeDom = element?.closest('[data-block-type]');

  if (nodeDom) {
    return ReactEditor.toSlateNode(editor, nodeDom) as Element;
  }

  return null;
}
