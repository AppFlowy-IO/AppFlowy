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

  if (isActive || !value) {
    Editor.removeMark(editor, key as string);
  } else if (value) {
    Editor.addMark(editor, key as string, value);
  }
}

/**
 * Check if the every text in the selection has the mark.
 * @param editor
 * @param format
 */
export function isMarkActive(editor: ReactEditor, format: EditorMarkFormat) {
  const selection = editor.selection;

  if (!selection) return false;

  const isExpanded = Range.isExpanded(selection);

  if (isExpanded) {
    const matches = Array.from(getSelectionNodeEntry(editor) || []);

    return matches.every((match) => {
      const [node] = match;

      const { text, ...attributes } = node;

      if (!text) {
        return true;
      }

      return !!(attributes as Record<string, boolean | string>)[format];
    });
  }

  const marks = Editor.marks(editor) as Record<string, string | boolean> | null;

  return marks ? !!marks[format] : false;
}

function getSelectionNodeEntry(editor: ReactEditor) {
  const selection = editor.selection;

  if (!selection) return null;

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

    return Editor.nodes(editor, {
      match: Text.isText,
      at: {
        anchor,
        focus,
      },
    });
  }

  return null;
}

/**
 * Get all marks in the current selection.
 * @param editor
 */
export function getAllMarks(editor: ReactEditor) {
  const selection = editor.selection;

  if (!selection) return null;

  const isExpanded = Range.isExpanded(selection);

  if (isExpanded) {
    const matches = Array.from(getSelectionNodeEntry(editor) || []);

    const marks: Record<string, string | boolean> = {};

    matches.forEach((match) => {
      const [node] = match;

      Object.entries(node).forEach(([key, value]) => {
        if (key !== 'text') {
          marks[key] = value;
        }
      });
    });

    return marks;
  }

  return Editor.marks(editor) as Record<string, string | boolean> | null;
}

export function removeMarks(editor: ReactEditor) {
  const marks = getAllMarks(editor);

  if (!marks) return;

  for (const key in marks) {
    Editor.removeMark(editor, key);
  }
}
