import { KeyboardEvent, useCallback, useEffect, useMemo } from 'react';

import { BaseRange, createEditor, Editor, NodeEntry, Range, Transforms, Element } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { withBlockPlugins } from '$app/components/editor/plugins/withBlockPlugins';
import { withShortcuts } from 'src/appflowy_app/components/editor/plugins/shortcuts';
import { withInlines } from '$app/components/editor/components/inline_nodes';
import { withYHistory, withYjs, YjsEditor } from '@slate-yjs/core';
import * as Y from 'yjs';
import { CustomEditor } from '$app/components/editor/command';
import { CodeNode, EditorNodeType } from '$app/application/document/document.types';
import { decorateCode } from '$app/components/editor/components/blocks/code/utils';
import isHotkey from 'is-hotkey';

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

export function useDecorateCodeHighlight(editor: ReactEditor) {
  return useCallback(
    (entry: NodeEntry): BaseRange[] => {
      const path = entry[1];

      const blockEntry = editor.above({
        at: path,
        match: (n) => !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined,
      });

      if (!blockEntry) return [];

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

export function useInlineKeyDown(editor: ReactEditor) {
  return useCallback(
    (e: KeyboardEvent<HTMLDivElement>) => {
      const selection = editor.selection;

      // Default left/right behavior is unit:'character'.
      // This fails to distinguish between two cursor positions, such as
      // <inline>foo<cursor/></inline> vs <inline>foo</inline><cursor/>.
      // Here we modify the behavior to unit:'offset'.
      // This lets the user step into and out of the inline without stepping over characters.
      // You may wish to customize this further to only use unit:'offset' in specific cases.
      if (selection && Range.isCollapsed(selection)) {
        const { nativeEvent } = e;

        if (
          isHotkey('left', nativeEvent) &&
          CustomEditor.beforeIsInlineNode(editor, selection, {
            unit: 'offset',
          })
        ) {
          e.preventDefault();
          Transforms.move(editor, { unit: 'offset', reverse: true });
          return;
        }

        if (isHotkey('right', nativeEvent) && CustomEditor.afterIsInlineNode(editor, selection, { unit: 'offset' })) {
          e.preventDefault();
          Transforms.move(editor, { unit: 'offset' });
          return;
        }
      }
    },
    [editor]
  );
}
