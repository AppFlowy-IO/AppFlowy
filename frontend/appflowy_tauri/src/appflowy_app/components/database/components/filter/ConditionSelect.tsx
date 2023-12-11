import React from 'react';
import Select from '@mui/material/Select';
import { FormControl, MenuItem, SelectProps } from '@mui/material';

function ConditionSelect({
  conditions,
  ...props
}: SelectProps & {
  conditions: {
    value: number;
    text: string;
  }[];
}) {
  return (
    <FormControl size={'small'} variant={'outlined'}>
      <Select
        {...props}
        sx={{
          '& .MuiSelect-select': {
            padding: 0,
            fontSize: '12px',
          },
          '& .MuiOutlinedInput-notchedOutline': {
            borderColor: 'transparent !important',
          },
        }}
      >
        {conditions.map((condition) => {
          return (
            <MenuItem key={condition.value} value={condition.value}>
              {condition.text}
            </MenuItem>
          );
        })}
      </Select>
    </FormControl>
  );
}

export default ConditionSelect;
