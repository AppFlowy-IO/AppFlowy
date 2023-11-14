import React, { useState } from 'react';
import Popover from '@mui/material/Popover';
import { RGBColor, SketchPicker } from 'react-color';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { Divider } from '@mui/material';

function CustomColorPicker({
  onChange,
  open,
  onClose,
  anchorPosition,
}: {
  open: boolean;
  onChange: (color: string) => void;
  anchorPosition?: {
    left: number;
    top: number;
  };
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const [color, setColor] = useState<RGBColor | undefined>();

  return (
    <Popover
      onMouseDown={(e) => e.stopPropagation()}
      disableAutoFocus={true}
      disableRestoreFocus={true}
      sx={{
        pointerEvents: 'none',
      }}
      PaperProps={{
        style: {
          pointerEvents: 'auto',
        },
        className: 'p-2',
      }}
      open={open}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'left',
      }}
      anchorReference={'anchorPosition'}
      anchorPosition={anchorPosition}
      onClose={onClose}
    >
      <SketchPicker
        onChange={(color) => {
          setColor(color.rgb);
        }}
        color={color}
      />
      <Divider />
      <div className={'z-10 flex justify-end bg-bg-body px-2 pt-2'}>
        <Button
          onClick={() => {
            onChange(`rgba(${color?.r}, ${color?.g}, ${color?.b}, ${color?.a})`);
          }}
          variant={'contained'}
        >
          {t('button.done')}
        </Button>
      </div>
    </Popover>
  );
}

export default CustomColorPicker;
