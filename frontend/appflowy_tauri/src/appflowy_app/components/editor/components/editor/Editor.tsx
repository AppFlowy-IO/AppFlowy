import React, { memo } from 'react';
import {
  EditorSelectedBlockProvider,
  useDecorate,
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

function Editor({ sharedType }: { sharedType: Y.XmlText; id: string }) {
  const { editor, initialValue, handleOnClickEnd, ...props } = useEditor(sharedType);
  const decorate = useDecorate(editor);
  const { onDOMBeforeInput, onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);
  const { selectedBlocks } = useEditorState(editor);

  if (editor.sharedRoot.length === 0) {
    return <CircularProgress className='m-auto' />;
  }

  return (
    <EditorSelectedBlockProvider value={selectedBlocks}>
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
    </EditorSelectedBlockProvider>
  );
}

export default memo(Editor);
