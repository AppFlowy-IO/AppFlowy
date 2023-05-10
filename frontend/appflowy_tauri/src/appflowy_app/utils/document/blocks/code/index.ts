import { getPointOfCurrentLineBeginning } from '$app/utils/document/blocks/text/delta';
import { Editor, Transforms } from 'slate';

export function indent(editor: Editor, distance: number) {
  const beginPoint = getPointOfCurrentLineBeginning(editor);
  const emptyStr = ''.padStart(distance);

  Transforms.insertText(editor, emptyStr, {
    at: beginPoint,
  });
}
export function outdent(editor: Editor, distance: number) {
  const beginPoint = getPointOfCurrentLineBeginning(editor);
  if (!beginPoint) return;
  const afterBeginPoint = Editor.after(editor, beginPoint, {
    distance,
  });
  if (!afterBeginPoint) return;
  const deleteChar = Editor.string(editor, {
    anchor: beginPoint,
    focus: afterBeginPoint,
  });
  const emptyStr = ''.padStart(distance);
  if (deleteChar !== emptyStr) {
    if (distance > 1) {
      outdent(editor, distance - 1);
    }
    return;
  }
  Transforms.delete(editor, {
    at: beginPoint,
    distance,
  });
}
