import React, { useRef, useState } from 'react';
import { MenuItem } from '@mui/material';
import { NumberFormatPB } from '@/services/backend';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { formatText } from '$app/components/database/components/field_types/number/const';
import NumberFormatMenu from '$app/components/database/components/field_types/number/NumberFormatMenu';

function NumberFormatSelect({ value, onChange }: { value: NumberFormatPB; onChange: (value: NumberFormatPB) => void }) {
  const ref = useRef<HTMLLIElement>(null);
  const [expanded, setExpanded] = useState(false);

  return (
    <>
      <MenuItem
        ref={ref}
        onClick={() => {
          setExpanded(!expanded);
        }}
        className={'flex w-full justify-between rounded-none'}
      >
        <div className='flex-1 text-xs font-medium'>{formatText(value)}</div>
        <MoreSvg className={`transform text-base ${expanded ? '' : 'rotate-90'}`} />
      </MenuItem>
      <NumberFormatMenu
        keepMounted={false}
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        PaperProps={{
          style: {
            maxHeight: 500,
          },
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        value={value}
        open={expanded}
        anchorEl={ref.current}
        onClose={() => setExpanded(false)}
        onChangeFormat={onChange}
      />
    </>
  );
}

export default NumberFormatSelect;
