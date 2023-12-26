import { createContext, useCallback, useEffect, useMemo, useState } from 'react';
import { EditorNodeType, CodeNode } from '$app/application/document/document.types';

import { createEditor, NodeEntry, BaseRange, Editor, Element } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { withBlockPlugins } from '$app/components/editor/plugins/withBlockPlugins';
import { decorateCode } from '$app/components/editor/components/blocks/code/utils';
import { withShortcuts } from '$app/components/editor/components/editor/shortcuts';
import { withInlines } from '$app/components/editor/components/inline_nodes';
import { withYjs, YjsEditor, withYHistory } from '@slate-yjs/core';
import * as Y from 'yjs';
import { CustomEditor } from '$app/components/editor/command';
import { proxySet, subscribeKey } from 'valtio/utils';

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

export function useEditorState(editor: ReactEditor) {
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

  return {
    selectedBlocks,
  };
}

export const EditorSelectedBlockContext = createContext<Set<string>>(new Set());

export const EditorSelectedBlockProvider = EditorSelectedBlockContext.Provider;
