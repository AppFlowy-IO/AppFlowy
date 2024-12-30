import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { isEmbedBlockTypes } from '@/application/slate-yjs/command/const';
import { getBlockEntry } from '@/application/slate-yjs/utils/editor';
import { BlockType } from '@/application/types';
import { Range } from 'slate';
import { ReactEditor } from 'slate-react';

export function withInsertBreak(editor: ReactEditor) {
  const { insertBreak, insertSoftBreak } = editor;

  editor.insertSoftBreak = () => {
    const { selection } = editor;

    if (!selection) return;

    const [node] = getBlockEntry(editor as YjsEditor);

    if (Range.isCollapsed(selection) && isEmbedBlockTypes(node.type as BlockType)) {
      CustomEditor.addBelowBlock(editor as YjsEditor, node.blockId as string, BlockType.Paragraph, {});
      return;
    }

    insertSoftBreak();
  };

  editor.insertBreak = () => {
    if ((editor as YjsEditor).readOnly) {
      insertBreak();
      return;
    }

    const { selection } = editor;

    if (!selection) return;

    if (Range.isCollapsed(selection)) {
      const [node] = getBlockEntry(editor as YjsEditor);

      if (isEmbedBlockTypes(node.type as BlockType)) {
        CustomEditor.addBelowBlock(editor as YjsEditor, node.blockId as string, BlockType.Paragraph, {});
        return;
      }
    }

    CustomEditor.insertBreak(editor as YjsEditor);
  };

  return editor;
}
