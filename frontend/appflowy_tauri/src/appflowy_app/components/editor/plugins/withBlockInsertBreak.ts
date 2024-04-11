import { ReactEditor } from 'slate-react';
import { EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';
import { Path, Transforms } from 'slate';
import { YjsEditor } from '@slate-yjs/core';
import { generateId } from '$app/components/editor/provider/utils/convert';

export function withBlockInsertBreak(editor: ReactEditor) {
  const { insertBreak } = editor;

  editor.insertBreak = (...args) => {
    const block = CustomEditor.getBlock(editor);

    if (!block) return insertBreak(...args);

    const [node, path] = block;

    const isEmbed = editor.isEmbed(node);

    const nextPath = Path.next(path);

    if (isEmbed) {
      CustomEditor.insertEmptyLine(editor as ReactEditor & YjsEditor, nextPath);
      editor.select(nextPath);
      return;
    }

    const type = node.type as EditorNodeType;

    const isBeginning = CustomEditor.focusAtStartOfBlock(editor);

    const isEmpty = CustomEditor.isEmptyText(editor, node);

    if (isEmpty) {
      const depth = path.length;
      let hasNextNode = false;

      try {
        hasNextNode = Boolean(editor.node(nextPath));
      } catch (e) {
        // do nothing
      }

      // if the node is empty and the depth is greater than 1, tab backward
      if (depth > 1 && !hasNextNode) {
        CustomEditor.tabBackward(editor);
        return;
      }

      // if the node is empty, convert it to a paragraph
      if (type !== EditorNodeType.Paragraph && type !== EditorNodeType.Page) {
        CustomEditor.turnToBlock(editor, { type: EditorNodeType.Paragraph });
        return;
      }
    } else if (isBeginning) {
      // insert line below the current block
      const newNodeType = [
        EditorNodeType.TodoListBlock,
        EditorNodeType.BulletedListBlock,
        EditorNodeType.NumberedListBlock,
      ].includes(type)
        ? type
        : EditorNodeType.Paragraph;

      Transforms.insertNodes(
        editor,
        {
          type: newNodeType,
          data: node.data ?? {},
          blockId: generateId(),
          children: [
            {
              type: EditorNodeType.Text,
              textId: generateId(),
              children: [
                {
                  text: '',
                },
              ],
            },
          ],
        },
        {
          at: path,
        }
      );
      return;
    }

    insertBreak(...args);
  };

  return editor;
}
