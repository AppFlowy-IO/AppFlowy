import { BlockType } from '@/application/types';
import { HeadingNode } from '@/components/editor/editor.type';
import { ReactEditor } from 'slate-react';
import { Element } from 'slate';

export function getBlockActionsPosition (editor: ReactEditor, blockElement: HTMLElement) {
  const editorDom = ReactEditor.toDOMNode(editor, editor);
  const editorDomRect = editorDom.getBoundingClientRect();
  const blockDomRect = blockElement.getBoundingClientRect();
  const parentBlockDom = blockElement.parentElement?.closest('[data-block-type]');

  const relativeTop = blockDomRect.top - editorDomRect.top;
  let relativeLeft = blockDomRect.left - editorDomRect.left;

  if (parentBlockDom?.getAttribute('data-block-type') === BlockType.QuoteBlock) {
    relativeLeft -= 16;
  }

  return {
    top: relativeTop,
    left: relativeLeft,
    height: blockDomRect.height,
  };
}

export function getBlockCssProperty (node: Element) {
  if ((node as HeadingNode).data.level) {
    return `level-${(node as HeadingNode).data.level} mt-[3px]`;
  }

  switch (node.type) {
    case BlockType.Paragraph:
    case BlockType.NumberedListBlock:
    case BlockType.BulletedListBlock:
    case BlockType.TodoListBlock:
    case BlockType.ToggleListBlock:
    case BlockType.QuoteBlock:
    case BlockType.SubpageBlock:
    case BlockType.CalloutBlock:
      return 'leading-[1.85em]';
    case BlockType.OutlineBlock:
      return 'py-[7px]';
    case BlockType.GridBlock:
    case BlockType.TableBlock:
      return 'my-3';
    case BlockType.GalleryBlock:
      return 'my-4';
    case BlockType.DividerBlock:
      return 'my-[-4px]';
    default:
      return 'my-2';
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
