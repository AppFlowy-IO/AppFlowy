import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { EditorNodeType, CodeNode } from '$app/application/document/document.types';

import { createEditor, NodeEntry, BaseRange, Editor, Element } from 'slate';
import { ReactEditor, useSelected, useSlateStatic, withReact } from 'slate-react';
import { withBlockPlugins } from '$app/components/editor/plugins/withBlockPlugins';
import { decorateCode } from '$app/components/editor/components/blocks/code/utils';
import { withShortcuts } from '$app/components/editor/components/editor/shortcuts';
import { withInlines } from '$app/components/editor/components/inline_nodes';
import { withYjs, YjsEditor, withYHistory } from '@slate-yjs/core';
import * as Y from 'yjs';
import { CustomEditor } from '$app/components/editor/command';

export function useEditor(sharedType: Y.XmlText) {
  const editor = useMemo(() => {
    if (!sharedType) return null;
    const e = withShortcuts(withBlockPlugins(withInlines(withReact(withYHistory(withYjs(createEditor(), sharedType))))));

    // Ensure editor always has at least 1 valid child
    const { normalizeNode } = e;

    e.normalizeNode = (entry) => {
      const [node] = entry;

      if (!Editor.isEditor(node) || node.children.length > 0) {
        return normalizeNode(entry);
      }

      // Ensure editor always has at least 1 valid child
      CustomEditor.insertEmptyLineAtEnd(e as ReactEditor & YjsEditor);
    };

    return e;
  }, [sharedType]) as ReactEditor & YjsEditor;

  const initialValue = useMemo(() => {
    return [];
  }, []);

  // Connect editor in useEffect to comply with concurrent mode requirements.
  useEffect(() => {
    YjsEditor.connect(editor);
    return () => {
      YjsEditor.disconnect(editor);
    };
  }, [editor]);

  const handleOnClickEnd = useCallback(() => {
    CustomEditor.insertEmptyLineAtEnd(editor);
  }, [editor]);

  return {
    editor,
    initialValue,
    handleOnClickEnd,
  };
}

export function useDecorate(editor: ReactEditor) {
  return useCallback(
    (entry: NodeEntry): BaseRange[] => {
      const path = entry[1];

      const blockEntry = path.length > 1 ? editor.node([path[0]]) : editor.node(path);

      const block = blockEntry[0] as CodeNode;

      if (block.type === EditorNodeType.CodeBlock) {
        const language = block.data.language;

        return decorateCode(entry, language, false);
      }

      return [];
    },
    [editor]
  );
}

export const EditorSelectedBlockContext = createContext<string[]>([]);

export function useSelectedBlock(block: Element) {
  const editor = useSlateStatic();
  const blockIds = useContext(EditorSelectedBlockContext);
  const isSelected = useSelected() && !editor.isSelectable(block);

  if (block.blockId === undefined) return false;
  return blockIds.includes(block.blockId) || isSelected;
}

export const EditorSelectedBlockProvider = EditorSelectedBlockContext.Provider;

export function useEditorSelectedBlock(editor: ReactEditor) {
  const [selectedBlockId, setSelectedBlockId] = useState<string[]>([]);
  const onSelectedBlock = useCallback((blockId: string) => {
    setSelectedBlockId([blockId]);
  }, []);

  const focusBlock = useCallback(
    (blockId: string) => {
      if (ReactEditor.isFocused(editor)) return;
      ReactEditor.focus(editor);
      const [block] = editor.nodes({
        at: [],
        match: (n) => Element.isElement(n) && n.blockId === blockId,
      });

      if (block) {
        const [, path] = block;

        editor.select(path);
        editor.collapse({
          edge: 'start',
        });
      }
    },
    [editor]
  );

  const clearSelectedBlock = useCallback(() => {
    if (selectedBlockId.length === 0) return;
    const blockId = selectedBlockId[0];

    setSelectedBlockId([]);
    if (blockId !== undefined) {
      focusBlock(blockId);
    }
  }, [focusBlock, selectedBlockId]);

  useEffect(() => {
    if (selectedBlockId.length > 0) {
      document.addEventListener('click', clearSelectedBlock);
      document.addEventListener('keydown', clearSelectedBlock);
    } else {
      document.removeEventListener('click', clearSelectedBlock);
      document.removeEventListener('keydown', clearSelectedBlock);
    }

    return () => {
      document.removeEventListener('click', clearSelectedBlock);
      document.removeEventListener('keydown', clearSelectedBlock);
    };
  }, [clearSelectedBlock, selectedBlockId.length]);

  return {
    selectedBlockId,
    onSelectedBlock,
  };
}
