import { BasePoint, Editor, Transforms } from 'slate';
import { ReactEditor } from 'slate-react';

export function getNodePath(editor: ReactEditor, target: HTMLElement) {
  const slateNode = ReactEditor.toSlateNode(editor, target);
  const path = ReactEditor.findPath(editor, slateNode);

  return path;
}

export function moveCursorToNodeEnd(editor: ReactEditor, target: HTMLElement) {
  const path = getNodePath(editor, target);
  const afterPath = Editor.after(editor, path);

  ReactEditor.focus(editor);

  if (afterPath) {
    const afterStart = Editor.start(editor, afterPath);

    moveCursorToPoint(editor, afterStart);
  } else {
    const beforeEnd = Editor.end(editor, path);

    moveCursorToPoint(editor, beforeEnd);
  }
}

export function moveCursorToPoint(editor: ReactEditor, point: BasePoint) {
  ReactEditor.focus(editor);
  Transforms.select(editor, point);
}
