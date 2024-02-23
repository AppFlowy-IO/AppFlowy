import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { Path } from 'slate';
import { YjsEditor } from '@slate-yjs/core';

export function withBlockInsertBreak(editor: ReactEditor) {
  const { insertBreak } = editor;

  editor.insertBreak = (...args) => {
    const block = CustomEditor.getBlock(editor);

    if (!block) return insertBreak(...args);

    const [node, path] = block;

    const isEmbed = editor.isEmbed(node);

    if (isEmbed) {
      const nextPath = Path.next(path);

      CustomEditor.insertEmptyLine(editor as ReactEditor & YjsEditor, nextPath);
      editor.select(nextPath);
      return;
    }

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
