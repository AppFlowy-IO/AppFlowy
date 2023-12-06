import React from 'react';
import { NumberFormatPB } from '@/services/backend';
import { Menu, MenuItem, MenuProps } from '@mui/material';
import { formats } from '$app/components/database/components/field_types/number/const';
import { ReactComponent as SelectCheckSvg } from '$app/assets/database/select-check.svg';

function NumberFormatMenu({
  value,
  onChangeFormat,
  ...props
}: MenuProps & {
  value: NumberFormatPB;
  onChangeFormat: (value: NumberFormatPB) => void;
}) {
  return (
    <Menu {...props}>
      {formats.map((format) => (
        <MenuItem
          onClick={() => {
            onChangeFormat(format.value as NumberFormatPB);
            props.onClose?.({}, 'backdropClick');
          }}
          className={'flex justify-between text-xs font-medium'}
          key={format.value}
        >
          <div className={'flex-1'}>{format.key}</div>
          {value === format.value && <SelectCheckSvg />}
        </MenuItem>
      ))}
    </Menu>
  );
}

export default NumberFormatMenu;
