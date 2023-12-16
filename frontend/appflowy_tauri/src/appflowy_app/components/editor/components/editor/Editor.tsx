import React, { useEffect } from 'react';
import { useDecorate, useEditor } from '$app/components/editor/components/editor/Editor.hooks';
import { ReactEditor, Slate } from 'slate-react';
import { CustomEditable } from '$app/components/editor/components/editor/CustomEditable';
import { EditorProps } from '$app/application/document/document.types';
import { SelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar';
import { useShortcuts } from '$app/components/editor/components/editor/shortcuts';
import { BlockActionsToolbar } from '$app/components/editor/components/tools/block_actions';
import { SlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel';
import { MentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel';
import { Transforms } from 'slate';
import { CircularProgress } from '@mui/material';

function Editor({ sharedType, appendTextRef, getRecentPages }: EditorProps) {
  const { editor, initialValue, handleOnClickEnd, ...props } = useEditor(sharedType);

  const decorate = useDecorate(editor);

  const { onDOMBeforeInput, onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);

  useEffect(() => {
    if (!appendTextRef) return;
    appendTextRef.current = (text: string) => {
      Transforms.insertNodes(
        editor,
        { type: 'paragraph', children: [{ text }] },
        {
          at: [0],
        }
      );
      ReactEditor.focus(editor);
      Transforms.select(editor, [0, 0]);
      Transforms.collapse(editor, { edge: 'start' });
    };

    return () => {
      appendTextRef.current = null;
    };
  }, [appendTextRef, editor]);
  if (editor.sharedRoot.length === 0) {
    return <CircularProgress className='m-auto' />;
  }

  return (
    <Slate editor={editor} initialValue={initialValue}>
      <SelectionToolbar />
      <BlockActionsToolbar />
      <CustomEditable
        {...props}
        onDOMBeforeInput={onDOMBeforeInput}
        onKeyDown={onShortcutsKeyDown}
        decorate={decorate}
        className={'caret-text-title outline-none focus:outline-none'}
      />
      <SlashCommandPanel />
      <MentionPanel getRecentPages={getRecentPages} />
      <div onClick={handleOnClickEnd} className={'relative bottom-0 left-0 h-10 w-full cursor-text'} />
    </Slate>
  );
}

export default Editor;
