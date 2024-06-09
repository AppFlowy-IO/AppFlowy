import { ReactEditor } from 'slate-react';
import { Editor, Text, Range, Element } from 'slate';
import { EditorInlineNodeType, EditorMarkFormat } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command/index';

export function toggleMark(
  editor: ReactEditor,
  mark: {
    key: EditorMarkFormat;
    value: string | boolean;
  }
) {
  if (CustomEditor.selectionIncludeRoot(editor)) {
    return;
  }

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
export function isMarkActive(editor: ReactEditor, format: EditorMarkFormat | EditorInlineNodeType) {
  const selection = editor.selection;

  if (!selection) return false;

  const isExpanded = Range.isExpanded(selection);

  if (isExpanded) {
    const texts = getSelectionTexts(editor);

    return texts.every((node) => {
      const { text, ...attributes } = node;

      if (!text) return true;
      return Boolean((attributes as Record<string, boolean | string>)[format]);
    });
  }

  const marks = Editor.marks(editor) as Record<string, string | boolean> | null;

  return marks ? !!marks[format] : false;
}

export function getSelectionTexts(editor: ReactEditor) {
  const selection = editor.selection;

  if (!selection) return [];

  const texts: Text[] = [];

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

    Array.from(
      Editor.nodes(editor, {
        at: {
          anchor,
          focus,
        },
      })
    ).forEach((match) => {
      const node = match[0] as Element;

      if (Text.isText(node)) {
        texts.push(node);
      } else if (Editor.isInline(editor, node)) {
        texts.push(...(node.children as Text[]));
      }
    });
  }

  return texts;
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
    const texts = getSelectionTexts(editor);

    const marks: Record<string, string | boolean> = {};

    texts.forEach((node) => {
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
