import React, { useEffect } from 'react';
import {
  EditorSelectedBlockProvider,
  useDecorate,
  useEditor,
  useEditorSelectedBlock,
} from '$app/components/editor/components/editor/Editor.hooks';
import { Slate } from 'slate-react';
import { CustomEditable } from '$app/components/editor/components/editor/CustomEditable';
import { EditorNodeType, EditorProps } from '$app/application/document/document.types';
import { SelectionToolbar } from '$app/components/editor/components/tools/selection_toolbar';
import { useShortcuts } from '$app/components/editor/components/editor/shortcuts';
import { BlockActionsToolbar } from '$app/components/editor/components/tools/block_actions';
import { SlashCommandPanel } from '$app/components/editor/components/tools/command_panel/slash_command_panel';
import { MentionPanel } from '$app/components/editor/components/tools/command_panel/mention_panel';
import { CircularProgress } from '@mui/material';
import { CustomEditor } from '$app/components/editor/command';

function Editor({ sharedType, appendTextRef }: EditorProps) {
  const { editor, initialValue, handleOnClickEnd, ...props } = useEditor(sharedType);
  const decorate = useDecorate(editor);
  const { onDOMBeforeInput, onKeyDown: onShortcutsKeyDown } = useShortcuts(editor);

  useEffect(() => {
    if (!appendTextRef) return;
    appendTextRef.current = (text: string) => {
      CustomEditor.insertLineAtStart(editor, {
        type: EditorNodeType.Paragraph,
        children: [{ text }],
      });
    };

    return () => {
      appendTextRef.current = null;
    };
  }, [appendTextRef, editor]);

  const { onSelectedBlock, selectedBlockId } = useEditorSelectedBlock(editor);

  if (editor.sharedRoot.length === 0) {
    return <CircularProgress className='m-auto' />;
  }

  return (
    <EditorSelectedBlockProvider value={selectedBlockId}>
      <Slate editor={editor} initialValue={initialValue}>
        <SelectionToolbar />
        <BlockActionsToolbar onSelectedBlock={onSelectedBlock} />
        <CustomEditable
          {...props}
          onDOMBeforeInput={onDOMBeforeInput}
          onKeyDown={onShortcutsKeyDown}
          decorate={decorate}
          className={'caret-text-title outline-none focus:outline-none'}
        />
        <SlashCommandPanel />
        <MentionPanel />
        <div onClick={handleOnClickEnd} className={'relative bottom-0 left-0 h-10 w-full cursor-text'} />
      </Slate>
    </EditorSelectedBlockProvider>
  );
}

export default Editor;
