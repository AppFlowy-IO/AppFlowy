import { Element, NodeEntry } from 'slate';
import { ReactEditor } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl py-[16px] font-bold';
    case 2:
      return 'text-2xl py-[12px] font-bold';
    case 3:
      return 'text-xl py-[8px] font-bold';
    default:
      return '';
  }
}

export function getBlock(editor: ReactEditor) {
  const match = CustomEditor.getBlock(editor);

  if (match) {
    const [node] = match as NodeEntry<Element>;

    return node;
  }

  return;
}

export function getEditorDomNode(editor: ReactEditor) {
  return ReactEditor.toDOMNode(editor, editor);
}
