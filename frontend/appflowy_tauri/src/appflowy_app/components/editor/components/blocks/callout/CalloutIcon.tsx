import React, { useCallback, useRef, useState } from 'react';
import { IconButton } from '@mui/material';
import { CalloutNode } from '$app/application/document/document.types';
import EmojiPicker from '$app/components/_shared/EmojiPicker';
import Popover from '@mui/material/Popover';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

function CalloutIcon({ node }: { node: CalloutNode }) {
  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);

  const editor = useSlateStatic();
  const handleEmojiSelect = useCallback(
    (emoji: string) => {
      CustomEditor.setCalloutIcon(editor, node, emoji);
    },
    [editor, node]
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
          onClose={() => {
            setOpen(false);
          }}
          anchorOrigin={{
            vertical: 'top',
            horizontal: 'right',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'left',
          }}
        >
          <EmojiPicker onEmojiSelect={handleEmojiSelect} />
        </Popover>
      )}
    </>
  );
}

export default React.memo(CalloutIcon);
