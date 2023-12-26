import { ReactEditor } from 'slate-react';

import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

export function withBlockDeleteBackward(editor: ReactEditor) {
  const { deleteBackward, removeNodes } = editor;

  editor.removeNodes = (...args) => {
    removeNodes(...args);
  };

  editor.deleteBackward = (unit) => {
    const match = CustomEditor.getBlock(editor);

    if (!match || !CustomEditor.focusAtStartOfBlock(editor)) {
      deleteBackward(unit);
      return;
    }

    const [node, path] = match;

    // if the current node is not a paragraph, convert it to a paragraph
    if (node.type !== EditorNodeType.Paragraph && node.type !== EditorNodeType.Page) {
      CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
      return;
    }

    const next = editor.next({
      at: path,
    });

    if (!next && path.length > 1) {
      CustomEditor.tabBackward(editor);
      return;
    }

    const [, ...children] = node.children;

    deleteBackward(unit);

    children.forEach((child, index) => {
      editor.liftNodes({
        at: [...path, index],
      });
    });
  };

  return editor;
}
