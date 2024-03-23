import { createContext, useEffect, useMemo, useState } from 'react';
import { proxySet, subscribeKey } from 'valtio/utils';
import { ReactEditor } from 'slate-react';
import { Element } from 'slate';

export function useInitialSelectedBlocks(editor: ReactEditor) {
  const selectedBlocks = useMemo(() => proxySet([]), []);
  const [selectedLength, setSelectedLength] = useState(0);

  subscribeKey(selectedBlocks, 'size', (v) => setSelectedLength(v));

  useEffect(() => {
    const { onChange } = editor;

    const onKeydown = (e: KeyboardEvent) => {
      if (!ReactEditor.isFocused(editor) && selectedLength > 0) {
        e.preventDefault();
        e.stopPropagation();
        const selectedBlockId = selectedBlocks.values().next().value;
        const [selectedBlock] = editor.nodes({
          at: [],
          match: (n) => Element.isElement(n) && n.blockId === selectedBlockId,
        });
        const [, path] = selectedBlock;

        editor.select(path);
        ReactEditor.focus(editor);
      }
    };

    if (selectedLength > 0) {
      editor.onChange = (...args) => {
        const isSelectionChange = editor.operations.every((arg) => arg.type === 'set_selection');

        if (isSelectionChange) {
          selectedBlocks.clear();
        }

        onChange(...args);
      };

      document.addEventListener('keydown', onKeydown);
    } else {
      editor.onChange = onChange;
      document.removeEventListener('keydown', onKeydown);
    }

    return () => {
      editor.onChange = onChange;
      document.removeEventListener('keydown', onKeydown);
    };
  }, [editor, selectedBlocks, selectedLength]);

  return selectedBlocks;
}

export const EditorSelectedBlockContext = createContext<Set<string>>(new Set());
export const EditorSelectedBlockProvider = EditorSelectedBlockContext.Provider;
