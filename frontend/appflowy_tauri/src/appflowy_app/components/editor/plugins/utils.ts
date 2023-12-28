import { Element, NodeEntry } from 'slate';
import { ReactEditor } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl pt-4 pb-2';
    case 2:
      return 'text-2xl pt-3 pb-2';
    case 3:
      return 'text-xl pt-2 pb-2';
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
