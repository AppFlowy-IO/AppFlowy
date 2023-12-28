import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CustomColorPicker } from '$app/components/editor/components/tools/_shared/CustomColorPicker';
import Typography from '@mui/material/Typography';
import { MenuItem, MenuList } from '@mui/material';
import { ReactComponent as SelectCheckSvg } from '$app/assets/select-check.svg';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { PopoverNoBackdropProps } from '$app/components/editor/components/tools/popover';

export interface ColorPickerProps {
  onFocus?: () => void;
  onBlur?: () => void;
  label?: string;
  color?: string;
  onChange?: (color: string) => void;
}
export function ColorPicker({ onFocus, onBlur, label, color, onChange }: ColorPickerProps) {
  const { t } = useTranslation();
  const colors = useMemo(
    () => [
      {
        key: 'default',
        name: t('colors.default'),
        color: '',
      },
      {
        key: 'gray',
        name: t('colors.gray'),
        color: '#78909c',
      },
      {
        key: 'brown',
        name: t('colors.brown'),
        color: '#8d6e63',
      },
      {
        key: 'orange',
        name: t('colors.orange'),
        color: '#ff9100',
      },
      {
        key: 'yellow',
        name: t('colors.yellow'),
        color: '#ffd600',
      },
      {
        key: 'green',
        name: t('colors.green'),
        color: '#00e676',
      },
      {
        key: 'blue',
        name: t('colors.blue'),
        color: '#448aff',
      },
      {
        key: 'purple',
        name: t('colors.purple'),
        color: '#e040fb',
      },
      {
        key: 'pink',
        name: t('colors.pink'),
        color: '#ff4081',
      },
      {
        key: 'red',
        name: t('colors.red'),
        color: '#ff5252',
      },
    ],
    [t]
  );

  const [openCustomColorPicker, setOpenCustomColorPicker] = useState(false);

  const customItemRef = useRef<HTMLLIElement | null>(null);

  useEffect(() => {
    if (openCustomColorPicker) {
      onFocus?.();
    } else {
      onBlur?.();
    }
  }, [openCustomColorPicker, onFocus, onBlur]);

  return (
    <div className={'flex min-w-[150px] flex-col'}>
      <Typography className={'px-3 pt-3 text-text-caption'} variant='subtitle2'>
        {label}
      </Typography>
      <MenuList disabledItemsFocusable={true}>
        <MenuItem
          onMouseEnter={() => {
            setOpenCustomColorPicker(true);
          }}
          onMouseLeave={() => {
            setOpenCustomColorPicker(false);
          }}
          className={'flex px-2 py-1'}
          ref={customItemRef}
        >
          <div className={'flex-1'}>{t('colors.custom')}</div>
          <MoreSvg className={'h-4 w-4'} />
          {openCustomColorPicker && (
            <CustomColorPicker
              anchorEl={customItemRef.current}
              open={openCustomColorPicker}
              onColorChange={onChange}
              onMouseDown={(e) => e.stopPropagation()}
              {...PopoverNoBackdropProps}
              onClose={() => {
                setOpenCustomColorPicker(false);
              }}
              onMouseUp={(e) => {
                // prevent editor blur
                e.stopPropagation();
              }}
              anchorOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              transformOrigin={{
                vertical: 'top',
                horizontal: 'left',
              }}
            />
          )}
        </MenuItem>
        {colors.map((c) => {
          return (
            <MenuItem
              className={'flex px-2 py-1'}
              key={c.key}
              onClick={() => {
                onChange?.(c.color);
              }}
            >
              <div
                className={'mr-2 flex h-4 w-4 items-center justify-center rounded-full border-2 p-0.5'}
                style={{
                  borderColor: c.color,
                }}
              >
                <div
                  className={'h-2 w-2 rounded-full'}
                  style={{
                    backgroundColor: c.color,
                  }}
                />
              </div>
              <div className={'flex-1'}>{c.name}</div>

              {color && color === c.color && <SelectCheckSvg />}
            </MenuItem>
          );
        })}
      </MenuList>
    </div>
  );
}
