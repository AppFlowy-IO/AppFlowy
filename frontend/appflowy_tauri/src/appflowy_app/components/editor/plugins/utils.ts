import { Editor, Element, Location, NodeEntry, Point, Range } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { ReactEditor } from 'slate-react';

export function getHeadingCssProperty(level: number) {
  switch (level) {
    case 1:
      return 'text-3xl pt-4';
    case 2:
      return 'text-2xl pt-3';
    case 3:
      return 'text-xl pt-2';
    default:
      return '';
  }
}

export function isDeleteBackwardAtStartOfBlock(editor: ReactEditor, type?: EditorNodeType) {
  const { selection } = editor;

  if (selection && Range.isCollapsed(selection)) {
    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n),
    });

    if (match) {
      const [node, path] = match as NodeEntry<Element>;

      if (type !== undefined && node.type !== type) return false;

      const start = Editor.start(editor, path);

      if (Point.equals(selection.anchor, start)) {
        return true;
      }
    }
  }

  return false;
}

export function getBlockEntry(editor: ReactEditor, at?: Location) {
  if (!editor.selection) return null;

  const entry = Editor.above(editor, {
    at,
    match: (n) => !Editor.isEditor(n) && Element.isElement(n),
  });

  return entry as NodeEntry<Element>;
}

export function getBlock(editor: ReactEditor, at?: Location) {
  const entry = getBlockEntry(editor, at);

  return entry?.[0];
}

export function getEditorDomNode(editor: ReactEditor) {
  return ReactEditor.toDOMNode(editor, editor);
}
