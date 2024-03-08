import React, { memo, useCallback } from 'react';
import {
  useDecorateCodeHighlight,
  useEditor,
  useInlineKeyDown,
} from '$app/components/editor/components/editor/Editor.hooks';
import { Slate } from 'slate-react';
import { CustomEditable } from '$app/components/editor/components/editor/CustomEditable';
import { SelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar';
import { useShortcuts } from 'src/appflowy_app/components/editor/plugins/shortcuts';
import { BlockActionsToolbar } from '$app/components/editor/components/tools/block_actions';

import { CircularProgress } from '@mui/material';
import { NodeEntry } from 'slate';
import {
  DecorateStateProvider,
  EditorSelectedBlockProvider,
  useInitialEditorState,
  SlashStateProvider,
  EditorInlineBlockStateProvider,
} from '$app/components/editor/stores';
import CommandPanel from '../tools/command_panel/CommandPanel';
import { EditorBlockStateProvider } from '$app/components/editor/stores/block';
import { LocalEditorProps } from '$app/application/document/document.types';

function Editor({ sharedType, disableFocus, caretColor = 'var(--text-title)' }: LocalEditorProps) {
  const { editor, initialValue, handleOnClickEnd, ...props } = useEditor(sharedType);
  const decorateCodeHighlight = useDecorateCodeHighlight(editor);
  const { onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);
  const withInlineKeyDown = useInlineKeyDown(editor);
  const {
    selectedBlocks,
    decorate: decorateCustomRange,
    decorateState,
    slashState,
    inlineBlockState,
    blockState,
  } = useInitialEditorState(editor);

  const decorate = useCallback(
    (entry: NodeEntry) => {
      const codeRanges = decorateCodeHighlight(entry);
      const customRanges = decorateCustomRange(entry);

      return [...codeRanges, ...customRanges];
    },
    [decorateCodeHighlight, decorateCustomRange]
  );

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      withInlineKeyDown(event);
      onShortcutsKeyDown(event);
    },
    [onShortcutsKeyDown, withInlineKeyDown]
  );

  if (editor.sharedRoot.length === 0) {
    return <CircularProgress className='m-auto' />;
  }

  return (
    <EditorSelectedBlockProvider value={selectedBlocks}>
      <DecorateStateProvider value={decorateState}>
        <EditorBlockStateProvider value={blockState}>
          <EditorInlineBlockStateProvider value={inlineBlockState}>
            <SlashStateProvider value={slashState}>
              <Slate editor={editor} initialValue={initialValue}>
                <BlockActionsToolbar />
                <SelectionToolbar />

                <CustomEditable
                  {...props}
                  disableFocus={disableFocus}
                  onKeyDown={onKeyDown}
                  decorate={decorate}
                  style={{
                    caretColor,
                  }}
                  className={`px-16 outline-none focus:outline-none`}
                />
                <CommandPanel />
                <div onClick={handleOnClickEnd} className={'relative bottom-0 left-0 h-10 w-full cursor-text'} />
              </Slate>
            </SlashStateProvider>
          </EditorInlineBlockStateProvider>
        </EditorBlockStateProvider>
      </DecorateStateProvider>
    </EditorSelectedBlockProvider>
  );
}

export default memo(Editor);
