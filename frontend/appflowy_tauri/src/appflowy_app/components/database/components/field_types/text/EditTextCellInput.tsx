import React, { useEffect, useRef } from 'react';
import { Popover, TextareaAutosize } from '@mui/material';

interface Props {
  editing: boolean;
  anchorEl: HTMLDivElement | null;
  width: number | undefined;
  onClose: () => void;
  text: string;
  onInput: (event: React.FormEvent<HTMLTextAreaElement>) => void;
}
function EditTextCellInput({ editing, anchorEl, width, onClose, text, onInput }: Props) {
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.focus();
      // set the cursor to the end of the text
      const length = textareaRef.current.value.length;

      textareaRef.current.setSelectionRange(length, length);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [textareaRef.current]);
  return (
    <Popover
      open={editing}
      anchorEl={anchorEl}
      PaperProps={{
        className: 'flex p-2 border border-blue-400',
        style: { width, borderRadius: 0, boxShadow: 'none' },
      }}
      transformOrigin={{
        vertical: 1,
        horizontal: 'left',
      }}
      transitionDuration={0}
      onClose={onClose}
    >
      <TextareaAutosize
        ref={textareaRef}
        className='resize-none text-sm'
        autoFocus
        autoCorrect='off'
        value={text}
        onInput={onInput}
      />
    </Popover>
  );
}

export default EditTextCellInput;
