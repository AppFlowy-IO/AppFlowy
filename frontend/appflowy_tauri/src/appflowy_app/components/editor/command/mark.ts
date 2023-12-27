import { ReactEditor } from 'slate-react';
import { Editor } from 'slate';
import { EditorMarkFormat } from '$app/application/document/document.types';

export function toggleMark(
  editor: ReactEditor,
  mark: {
    key: EditorMarkFormat;
    value: string | boolean;
  }
) {
  const { key, value } = mark;

  const isActive = isMarkActive(editor, key);

  if (isActive) {
    Editor.removeMark(editor, key as string);
  } else {
    Editor.addMark(editor, key as string, value);
  }
}

export function isMarkActive(editor: ReactEditor, format: EditorMarkFormat) {
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
