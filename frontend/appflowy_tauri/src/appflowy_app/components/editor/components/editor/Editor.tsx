import React, { memo, useCallback } from 'react';
import {
  DecorateStateProvider,
  EditorSelectedBlockProvider,
  useDecorateCodeHighlight,
  useEditor,
  useEditorState,
} from '$app/components/editor/components/editor/Editor.hooks';
import { Slate } from 'slate-react';
import { CustomEditable } from '$app/components/editor/components/editor/CustomEditable';
import { SelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar';
import { useShortcuts } from '$app/components/editor/components/editor/shortcuts';
import { BlockActionsToolbar } from '$app/components/editor/components/tools/block_actions';
import { SlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel';
import { MentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel';
import { CircularProgress } from '@mui/material';
import * as Y from 'yjs';
import { NodeEntry } from 'slate';

function Editor({ sharedType }: { sharedType: Y.XmlText; id: string }) {
  const { editor, initialValue, handleOnClickEnd, ...props } = useEditor(sharedType);
  const decorateCodeHighlight = useDecorateCodeHighlight(editor);
  const { onDOMBeforeInput, onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);
  const { selectedBlocks, decorate: decorateCustomRange, decorateState } = useEditorState(editor);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      const codeRanges = decorateCodeHighlight(entry);
      const customRanges = decorateCustomRange(entry);

      return [...codeRanges, ...customRanges];
    },
    [decorateCodeHighlight, decorateCustomRange]
  );

  if (editor.sharedRoot.length === 0) {
    return <CircularProgress className='m-auto' />;
  }

  return (
    <EditorSelectedBlockProvider value={selectedBlocks}>
      <DecorateStateProvider value={decorateState}>
        <Slate editor={editor} initialValue={initialValue}>
          <SelectionToolbar />
          <BlockActionsToolbar />
          <CustomEditable
            {...props}
            onDOMBeforeInput={onDOMBeforeInput}
            onKeyDown={onShortcutsKeyDown}
            decorate={decorate}
            className={'px-16 caret-text-title outline-none focus:outline-none'}
          />
          <SlashCommandPanel />
          <MentionPanel />
          <div onClick={handleOnClickEnd} className={'relative bottom-0 left-0 h-10 w-full cursor-text'} />
        </Slate>
      </DecorateStateProvider>
    </EditorSelectedBlockProvider>
  );
}

export default memo(Editor);
