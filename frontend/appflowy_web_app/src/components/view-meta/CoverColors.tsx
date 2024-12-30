import { IconButton } from '@mui/material';
import React from 'react';
import { colorMap } from '@/utils/color';

const colors = Object.entries(colorMap);

function Colors ({ onDone }: { onDone?: (value: string) => void }) {
  return (
    <div className={'flex flex-wrap justify-center gap-2 p-2 pb-6'}>
      {colors.map(([name, value]) => (
        <IconButton
          key={name}
          className={'h-9 w-9 p-1 cursor-pointer rounded rounded-full'}
          onClick={() => onDone?.(name)}
        >
          <div
            style={{ backgroundColor: value }}
            className={'h-7 w-7 rounded rounded-full'}
          />
        </IconButton>
      ))}
    </div>
  );
}

export default Colors;
