import { ReactEditor } from 'slate-react';
import { Editor } from 'slate';

export function toggleMark(
  editor: ReactEditor,
  mark: {
    key: string;
    value: string | boolean;
  }
) {
  const { key, value } = mark;

  const isActive = isMarkActive(editor, key);

  if (isActive) {
    Editor.removeMark(editor, key);
  } else {
    Editor.addMark(editor, key, value);
  }
}

export function isMarkActive(editor: ReactEditor, format: string) {
  const marks = Editor.marks(editor) as Record<string, string | boolean> | null;

  return marks ? !!marks[format] : false;
}

export function removeMarks(editor: ReactEditor) {
  const marks = Editor.marks(editor);

  if (!marks) return;

  for (const key in marks) {
    Editor.removeMark(editor, key);
  }
}
