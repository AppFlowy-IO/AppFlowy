import React, { useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { Color, SketchPicker } from 'react-color';

import { Divider } from '@mui/material';

export function CustomColorPicker({
  onColorChange,
  ...props
}: {
  onColorChange?: (color: string) => void;
} & PopoverProps) {
  const [color, setColor] = useState<Color | undefined>();

  return (
    <Popover {...props}>
      <SketchPicker
        onChange={(color) => {
          setColor(color.rgb);
          onColorChange?.(color.hex);
        }}
        color={color}
      />
      <Divider />
    </Popover>
  );
}
