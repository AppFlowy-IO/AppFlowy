import { ReactEditor } from 'slate-react';
import { Editor, Text, Range } from 'slate';
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
  const selection = editor.selection;

  if (!selection) return false;

  const isExpanded = Range.isExpanded(selection);

  if (isExpanded) {
    let anchor = Range.start(selection);
    const focus = Range.end(selection);
    const isEnd = Editor.isEnd(editor, anchor, anchor.path);

    if (isEnd) {
      const after = Editor.after(editor, anchor);

      if (after) {
        anchor = after;
      }
    }

    const matches = Array.from(
      Editor.nodes(editor, {
        match: Text.isText,
        at: {
          anchor,
          focus,
        },
      })
    );

    return matches.every((match) => {
      const [node] = match;

      const { text, ...attributes } = node;

      if (!text) {
        return true;
      }

      return !!attributes[format];
    });
  }

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
