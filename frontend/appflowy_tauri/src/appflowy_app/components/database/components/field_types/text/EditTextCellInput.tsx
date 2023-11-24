import React from 'react';
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
  return (
    <Popover
      open={editing}
      anchorEl={anchorEl}
      PaperProps={{
        className: 'flex p-2 border border-blue-400',
        style: { width, height: anchorEl?.offsetHeight, borderRadius: 0, boxShadow: 'none' },
      }}
      transformOrigin={{
        vertical: 1,
        horizontal: 'left',
      }}
      transitionDuration={0}
      onClose={onClose}
      keepMounted={false}
    >
      <TextareaAutosize className='resize-none text-sm' autoFocus autoCorrect='off' value={text} onInput={onInput} />
    </Popover>
  );
}

export default EditTextCellInput;
