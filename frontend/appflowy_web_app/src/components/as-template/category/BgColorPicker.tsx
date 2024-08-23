import { IconButton, InputLabel, Tooltip } from '@mui/material';
import React, { forwardRef } from 'react';
import { useTranslation } from 'react-i18next';

const colors = [
  '#FFF5F5',
  '#FFF9DB',
  '#FFF0F6',
  '#FFF4E6',
  '#F3F0FF',
  '#DAD8FF',
  '#FFF0F6',
  '#FFE4E1',
  '#E2EFF5',
  '#C5D0E6',
  '#FFE0E6',
  '#F0DFF0',
  '#E0FFFF',
  '#AFEEEE',
];

function BgColorPicker ({ value, onChange }: {
  value: string;
  onChange: (value: string) => void;
}, ref: React.Ref<HTMLDivElement>) {
  const { t } = useTranslation();

  return (
    <div ref={ref} className={'flex flex-col gap-2'}>
      <InputLabel>{t('template.category.bgColor')}</InputLabel>
      <div className={'flex gap-2 flex-wrap'}>
        {colors.map((color, index) => {
          return (
            <Tooltip title={color} key={index} arrow={true} placement={'top'}>
              <IconButton
                className={`flex items-center justify-center cursor-pointer p-2`}
                style={{
                  backgroundColor: value === color ? 'var(--fill-list-hover)' : undefined,
                }}
                key={index}
                onClick={() => onChange(color)}
              >
                <div className={'rounded-full w-6 h-6'} style={{ backgroundColor: color }} />
              </IconButton>
            </Tooltip>
          );
        })}
      </div>
    </div>
  );
}

export default forwardRef(BgColorPicker);