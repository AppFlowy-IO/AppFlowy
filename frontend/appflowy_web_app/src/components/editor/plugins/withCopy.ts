import { ReactEditor } from 'slate-react';
import { Range } from 'slate';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { YjsEditor } from '@/application/slate-yjs';
import { isEmbedBlockTypes } from '@/application/slate-yjs/command/const';
import { BlockType } from '@/application/types';

export const withCopy = (editor: ReactEditor) => {
  const { setFragmentData } = editor;

  editor.setFragmentData = (data: Pick<DataTransfer, 'getData' | 'setData'>) => {
    const { selection } = editor;

    if (!selection) {
      return;
    }

    if (Range.isCollapsed(selection)) {
      const [node] = getBlockEntry(editor as YjsEditor);

      if (node && isEmbedBlockTypes(node.type as BlockType)) {
        const fragment = editor.getFragment();
        const string = JSON.stringify(fragment);
        const encoded = window.btoa(encodeURIComponent(string));

        data.setData(`application/x-appflowy-fragment`, encoded);
      }

      return;
    }

    setFragmentData(<DataTransfer>data);
  };

  return editor;
};
