import React from 'react';
import { colorMap } from '$app/utils/color';

const colors = Object.entries(colorMap);

function Colors({ onDone }: { onDone?: (value: string) => void }) {
  return (
    <div className={'flex flex-wrap justify-center gap-2 p-2 pb-6'}>
      {colors.map(([name, value]) => (
        <div
          key={name}
          className={'h-9 w-9 cursor-pointer rounded rounded-full'}
          style={{ backgroundColor: value }}
          onClick={() => onDone?.(name)}
        />
      ))}
    </div>
  );
}

export default Colors;
