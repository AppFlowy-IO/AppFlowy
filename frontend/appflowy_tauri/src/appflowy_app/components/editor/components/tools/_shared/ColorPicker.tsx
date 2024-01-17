import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CustomColorPicker } from '$app/components/editor/components/tools/_shared/CustomColorPicker';
import Typography from '@mui/material/Typography';
import { IconButton, MenuItem, MenuList } from '@mui/material';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { PopoverNoBackdropProps } from '$app/components/editor/components/tools/popover';
import Tooltip from '@mui/material/Tooltip';
import { useAppSelector } from '$app/stores/store';
import { ThemeMode } from '$app_reducers/current-user/slice';

export interface ColorPickerProps {
  onFocus?: () => void;
  onBlur?: () => void;
  label?: string;
  color?: string;
  onChange?: (color: string) => void;
}
export function ColorPicker({ onFocus, onBlur, label, color = '', onChange }: ColorPickerProps) {
  const { t } = useTranslation();
  const isDark = useAppSelector((state) => state.currentUser?.userSetting?.themeMode === ThemeMode.Dark);
  const [selectedColor, setSelectedColor] = useState(color);

  useEffect(() => {
    setSelectedColor(color);
  }, [color]);

  const handleColorChange = (color: string) => {
    setSelectedColor(color);
    onChange?.(color);
  };

  const colors = useMemo(() => {
    return !isDark
      ? [
          '#e8e0ff',
          '#ffd6e8',
          '#f5d0ff',
          '#e1fbff',
          '#ffebcc',
          '#fff7cc',
          '#e8ffcc',
          '#e8f4ff',
          '#fff2cd',
          '#d9d9d9',
          '#f0f0f0',
        ]
      : [
          '#4D4078',
          '#7B2CBF',
          '#FFB800',
          '#00B800',
          '#00B8FF',
          '#007BFF',
          '#B800FF',
          '#FF00B8',
          '#FF0000',
          '#FF6C00',
          '#FFD800',
        ];
  }, [isDark]);

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
          className={'mx-2 mb-2 flex px-2.5 py-1'}
          ref={customItemRef}
        >
          <div className={'flex-1 text-xs'}>{t('colors.custom')}</div>
          <MoreSvg className={'h-4 w-4'} />
          {openCustomColorPicker && (
            <CustomColorPicker
              anchorEl={customItemRef.current}
              open={openCustomColorPicker}
              onColorChange={handleColorChange}
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
        <div className={'flex flex-grow flex-wrap items-center gap-1 px-3 py-0'}>
          <Tooltip title={t('colors.default')}>
            <IconButton
              className={'rounded-full'}
              onClick={() => {
                handleColorChange('');
              }}
            >
              <DeleteSvg />
            </IconButton>
          </Tooltip>
          {colors.map((c) => {
            return (
              <IconButton
                key={c}
                onClick={() => {
                  handleColorChange(c);
                }}
                className={'flex h-6 w-6 cursor-pointer items-center justify-center rounded-full p-1'}
                style={{
                  backgroundColor: c === selectedColor ? 'var(--content-blue-100)' : undefined,
                }}
              >
                <div
                  className={'h-full w-full rounded-full'}
                  style={{
                    backgroundColor: c,
                  }}
                />
              </IconButton>
            );
          })}
        </div>
      </MenuList>
    </div>
  );
}
