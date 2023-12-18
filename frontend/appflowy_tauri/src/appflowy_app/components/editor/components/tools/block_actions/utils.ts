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
      return getHeadingCssProperty((node as HeadingNode).data.level);
    case EditorNodeType.CodeBlock:
    case EditorNodeType.CalloutBlock:
      return 'my-2';
  }
}
