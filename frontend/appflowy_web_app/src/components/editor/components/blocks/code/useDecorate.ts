import { BlockType } from '@/application/collab.type';
import { useEditorContext } from '@/components/editor/EditorContext';
import { decorateCode } from './utils';
import { CodeNode } from '@/components/editor/editor.type';
import { useMemo } from 'react';
import { BaseRange, Editor, NodeEntry, Element } from 'slate';
import { ReactEditor } from 'slate-react';

export function useDecorate(editor: ReactEditor) {
  const grammars = useEditorContext().codeGrammars;

  return useMemo(() => {
    return (entry: NodeEntry): BaseRange[] => {
      if (!entry) return [];
      const path = entry[1];

      const blockEntry = editor.above({
        at: path,
        match: (n) =>
          !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type === BlockType.CodeBlock,
      });

      if (!blockEntry) return [];

      const block = blockEntry[0] as CodeNode;

      if (block.type === BlockType.CodeBlock && grammars?.[block.blockId]) {
        return decorateCode(entry, grammars[block.blockId]);
      }

      return [];
    };
  }, [editor, grammars]);
}
