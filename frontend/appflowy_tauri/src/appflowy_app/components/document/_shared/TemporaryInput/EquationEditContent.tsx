import React from 'react';
import TextField from '@mui/material/TextField';
import { CheckOutlined, FunctionsOutlined } from '@mui/icons-material';
import { Divider, IconButton, InputAdornment } from '@mui/material';

function EquationEditContent({
  value,
  onChange,
  onConfirm,
}: {
  value: string;
  onChange: (newVal: string) => void;
  onConfirm: () => void;
}) {
  return (
    <div className={'flex p-2'}>
      <TextField
        placeholder={'E = mc^2'}
        autoFocus={true}
        label='Equation'
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
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
      <Divider sx={{ height: 'initial', marginLeft: '10px' }} orientation='vertical' />
      <IconButton onClick={onConfirm} color='primary' sx={{ p: '10px' }} aria-label='directions'>
        <CheckOutlined />
      </IconButton>
    </div>
  );
}

export default EquationEditContent;
