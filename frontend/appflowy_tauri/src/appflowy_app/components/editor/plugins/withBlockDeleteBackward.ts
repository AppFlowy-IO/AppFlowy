import { ReactEditor } from 'slate-react';

import { isDeleteBackwardAtStartOfBlock } from '$app/components/editor/plugins/utils';
import { EditorNodeType } from '$app/application/document/document.types';
import { Editor, Element, NodeEntry } from 'slate';
import { CustomEditor } from '$app/components/editor/command';

export function withBlockDeleteBackward(editor: ReactEditor) {
  const { deleteBackward } = editor;

  editor.deleteBackward = (...args) => {
    if (!isDeleteBackwardAtStartOfBlock(editor)) {
      deleteBackward(...args);
      return;
    }

    const [match] = Editor.nodes(editor, {
      match: (n) => !Editor.isEditor(n) && Element.isElement(n) && Editor.isBlock(editor, n),
    });

    const [node] = match as NodeEntry<Element>;

    // if the current node is not a paragraph, convert it to a paragraph
    if (node.type !== EditorNodeType.Paragraph) {
      CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
      return;
    }

    const level = node.level;

    if (!level) {
      deleteBackward(...args);
      return;
    }

    const nextNode = CustomEditor.findNextNode(editor, node, level);

    if (nextNode) {
      deleteBackward(...args);
      return;
    }

    if (level > 1) {
      CustomEditor.tabBackward(editor);
      return;
    }

    deleteBackward(...args);
  };

  return editor;
}
