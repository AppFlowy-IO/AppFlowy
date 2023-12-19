import { ReactEditor } from 'slate-react';
import { Editor, Element, NodeEntry } from 'slate';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

export function withBlockInsertBreak(editor: ReactEditor) {
  const { insertBreak } = editor;

  editor.insertBreak = (...args) => {
    const nodeEntry = Editor.above(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n),
    });

    if (!nodeEntry) return insertBreak(...args);

    const [node] = nodeEntry as NodeEntry<Element>;
    const type = node.type as EditorNodeType;

    if (type === EditorNodeType.Page) {
      insertBreak(...args);
      return;
    }

    const isEmpty = Editor.isEmpty(editor, node);

    // if the node is empty, convert it to a paragraph
    if (isEmpty && type !== EditorNodeType.Paragraph) {
      CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
      return;
    }

    insertBreak(...args);
  };

  return editor;
}
