import React, { useCallback, useRef, useState } from 'react';
import { IconButton } from '@mui/material';
import { CalloutNode } from '$app/application/document/document.types';
import EmojiPicker from '$app/components/_shared/emoji_picker/EmojiPicker';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

function CalloutIcon({ node }: { node: CalloutNode }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);
  const editor = useSlateStatic();

  const handleClose = useCallback(() => {
    setOpen(false);
    const path = ReactEditor.findPath(editor, node);

    ReactEditor.focus(editor);
    editor.select(path);
    editor.collapse({
      edge: 'start',
    });
  }, [editor, node]);
  const handleEmojiSelect = useCallback(
    (emoji: string) => {
      CustomEditor.setCalloutIcon(editor, node, emoji);
      handleClose();
    },
    [editor, node, handleClose]
  );

  return (
    <>
      <IconButton
        contentEditable={false}
        ref={ref}
        onClick={() => {
          setOpen(true);
        }}
        className={`h-8 w-8 p-1`}
      >
        {node.data.icon}
      </IconButton>
      {open && (
        <Popover
          {...PopoverCommonProps}
          className={'border-none bg-transparent shadow-none'}
          anchorEl={ref.current}
          disableAutoFocus={true}
          open={open}
          onClose={handleClose}
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'right',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
        >
          <EmojiPicker onEscape={handleClose} onEmojiSelect={handleEmojiSelect} />
        </Popover>
      )}
    </>
  );
}

export default React.memo(CalloutIcon);
