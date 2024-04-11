import { Element, NodeEntry } from 'slate';
import { ReactEditor } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl pt-[10px] pb-[8px] font-bold';
    case 2:
      return 'text-2xl pt-[8px] pb-[6px] font-bold';
    case 3:
      return 'text-xl pt-[4px] font-bold';
    case 4:
      return 'text-lg pt-[4px] font-bold';
    case 5:
      return 'text-base pt-[4px] font-bold';
    case 6:
      return 'text-sm pt-[4px] font-bold';
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
