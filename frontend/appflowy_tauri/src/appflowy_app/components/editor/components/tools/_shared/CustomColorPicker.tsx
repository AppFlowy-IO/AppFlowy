import React, { useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { RGBColor, SketchPicker } from 'react-color';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { Divider } from '@mui/material';

export function CustomColorPicker({
  onColorChange,
  ...props
}: {
  onColorChange?: (color: string) => void;
} & PopoverProps) {
  const { t } = useTranslation();
  const [color, setColor] = useState<RGBColor | undefined>();

  return (
    <Popover {...props}>
      <SketchPicker
        onChange={(color) => {
          setColor(color.rgb);
        }}
        color={color}
      />
      <Divider />
      <div className={'z-10 flex justify-end bg-bg-body px-2 py-2'}>
        <Button
          size={'small'}
          onClick={() => {
            onColorChange?.(`rgba(${color?.r}, ${color?.g}, ${color?.b}, ${color?.a})`);
          }}
          variant={'outlined'}
        >
          {t('button.done')}
        </Button>
      </div>
    </Popover>
  );
}
