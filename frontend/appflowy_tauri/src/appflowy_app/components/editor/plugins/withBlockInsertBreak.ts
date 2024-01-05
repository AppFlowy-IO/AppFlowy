import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

export function withBlockInsertBreak(editor: ReactEditor) {
  const { insertBreak } = editor;

  editor.insertBreak = (...args) => {
    const block = CustomEditor.getBlock(editor);

    if (!block) return insertBreak(...args);

    const [node] = block;
    const type = node.type as EditorNodeType;

    const isEmpty = CustomEditor.isEmptyText(editor, node);

    // if the node is empty, convert it to a paragraph
    if (isEmpty && type !== EditorNodeType.Paragraph && type !== EditorNodeType.Page) {
      CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
      return;
    }

    insertBreak(...args);
  };

  return editor;
}
