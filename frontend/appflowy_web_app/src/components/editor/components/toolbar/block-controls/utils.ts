import { BlockType } from '@/application/types';
import { getHeadingCssProperty } from '@/components/editor/components/blocks/heading';
import { HeadingNode } from '@/components/editor/editor.type';
import { ReactEditor } from 'slate-react';
import { Element } from 'slate';

export function getBlockActionsPosition (editor: ReactEditor, blockElement: HTMLElement) {
  const editorDom = ReactEditor.toDOMNode(editor, editor);
  const editorDomRect = editorDom.getBoundingClientRect();
  const blockDomRect = blockElement.getBoundingClientRect();

  const relativeTop = blockDomRect.top - editorDomRect.top;
  const relativeLeft = blockDomRect.left - editorDomRect.left;

  return {
    top: relativeTop,
    left: relativeLeft,
    height: blockDomRect.height,
  };
}

export function getBlockCssProperty (node: Element) {
  switch (node.type) {
    case BlockType.HeadingBlock:
      return `${getHeadingCssProperty((node as HeadingNode).data.level)} mt-1`;
    case BlockType.CodeBlock:
      return 'my-3';
    case BlockType.CalloutBlock:
      return 'my-5';
    case BlockType.EquationBlock:
    case BlockType.GridBlock:
      return 'my-3';
    case BlockType.DividerBlock:
      return 'my-0';
    default:
      return 'pt-[3px]';
  }
}

export function findEventNode (
  editor: ReactEditor,
  {
    x,
    y,
  }: {
    x: number;
    y: number;
  },
): Element | null {
  const element = document.elementFromPoint(x, y);
  const nodeDom = element?.closest('[data-block-type]');

  if (nodeDom) {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    return ReactEditor.toSlateNode(editor, nodeDom);
  }

  return null;
}
