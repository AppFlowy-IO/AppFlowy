import React, { useCallback } from 'react';
import { Popover, TextareaAutosize } from '@mui/material';

interface Props {
  editing: boolean;
  anchorEl: HTMLDivElement | null;
  onClose: () => void;
  text: string;
  onInput: (event: React.FormEvent<HTMLTextAreaElement>) => void;
}

function EditTextCellInput({ editing, anchorEl, onClose, text, onInput }: Props) {
  const handleEnter = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    const shift = e.shiftKey;

    // If shift is pressed, allow the user to enter a new line, otherwise close the popover
    if (!shift && e.key === 'Enter') {
      e.preventDefault();
      e.stopPropagation();
      onClose();
    }
  };

  const setRef = useCallback((e: HTMLTextAreaElement | null) => {
    if (!e) return;
    const selectionStart = e.value.length;

    e.setSelectionRange(selectionStart, selectionStart);
  }, []);

  return (
    <Popover
      open={editing}
      anchorEl={anchorEl}
      disableRestoreFocus={true}
      PaperProps={{
        className: 'flex p-2 border border-blue-400',
        style: { width: anchorEl?.offsetWidth, minHeight: anchorEl?.offsetHeight, borderRadius: 0, boxShadow: 'none' },
      }}
      transformOrigin={{
        vertical: 1,
        horizontal: 'left',
      }}
      transitionDuration={0}
      onClose={onClose}
      keepMounted={false}
      onKeyDown={(e) => {
        if (e.key === 'Escape') {
          e.stopPropagation();
          e.preventDefault();
          onClose();
        }
      }}
    >
      <TextareaAutosize
        className='w-full resize-none whitespace-break-spaces break-all text-sm'
        autoFocus
        ref={setRef}
        spellCheck={false}
        autoCorrect='off'
        value={text}
        onInput={onInput}
        onKeyDown={handleEnter}
      />
    </Popover>
  );
}

export default EditTextCellInput;
