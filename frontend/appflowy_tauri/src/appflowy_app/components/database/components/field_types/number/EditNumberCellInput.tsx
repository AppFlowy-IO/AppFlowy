import React from 'react';
import { Popover } from '@mui/material';
import InputBase from '@mui/material/InputBase';

function EditNumberCellInput({
  editing,
  anchorEl,
  width,
  onClose,
  value,
  onChange,
}: {
  editing: boolean;
  anchorEl: HTMLDivElement | null;
  width: number | undefined;
  onClose: () => void;
  value: string;
  onChange: (value: string) => void;
}) {
  const handleInput = (e: React.FormEvent<HTMLInputElement>) => {
    const value = (e.target as HTMLInputElement).value;

    onChange(value);
  };

  return (
    <Popover
      keepMounted={false}
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
    >
      <InputBase
        inputProps={{
          sx: {
            padding: 0,
            textAlign: 'right',
          },
        }}
        autoFocus={true}
        value={value}
        onInput={handleInput}
      />
    </Popover>
  );
}

export default EditNumberCellInput;
