import { BlockType } from '@/application/collab.type';
import { decorateCode } from '@/components/editor/components/blocks/code/utils';
import { CodeNode } from '@/components/editor/editor.type';
import { useCallback } from 'react';
import { BaseRange, Editor, NodeEntry, Element } from 'slate';
import { ReactEditor } from 'slate-react';

export function useDecorate(editor: ReactEditor) {
  return useCallback(
    (entry: NodeEntry): BaseRange[] => {
      const path = entry[1];

      const blockEntry = editor.above({
        at: path,
        match: (n) =>
          !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type === BlockType.CodeBlock,
      });

      if (!blockEntry) return [];

      const block = blockEntry[0] as CodeNode;

      if (block.type === BlockType.CodeBlock) {
        const language = block.data.language;

        return decorateCode(entry, language, false);
      }

      return [];
    },
    [editor]
  );
}
