import React from 'react';
import TextField from '@mui/material/TextField';
import { CheckOutlined, FunctionsOutlined } from '@mui/icons-material';
import { IconButton, InputAdornment } from '@mui/material';

function EquationEditContent({
  value,
  onChange,
  onConfirm,
  placeholder = 'E = mc^2',
  multiline = false,
}: {
  value: string;
  placeholder?: string;
  onChange: (newVal: string) => void;
  onConfirm: () => void;
  multiline?: boolean;
}) {
  return (
    <div className={'flex items-center p-2'}>
      <TextField
        placeholder={placeholder}
        autoFocus={true}
        multiline={multiline}
        label='Equation'
        onKeyDown={(e) => {
          if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            onConfirm();
          }
        }}
        InputProps={{
          startAdornment: (
            <InputAdornment position='start'>
              <FunctionsOutlined />
            </InputAdornment>
          ),
        }}
        variant='standard'
        value={value}
        onChange={(e) => {
          const newVal = e.target.value;

          if (newVal === value) return;
          onChange(newVal);
        }}
      />

      <IconButton
        className={'h-[23px] w-[23px]'}
        onClick={onConfirm}
        color='primary'
        sx={{ p: '10px', m: '10px' }}
        aria-label='directions'
      >
        <CheckOutlined />
      </IconButton>
    </div>
  );
}

export default EquationEditContent;
