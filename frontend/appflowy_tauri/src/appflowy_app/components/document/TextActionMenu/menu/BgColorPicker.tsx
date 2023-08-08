import React, { useCallback, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import ColorPicker from '$app/components/document/TextActionMenu/menu/ColorPicker';
import { FormatColorFill, FormatColorText } from '@mui/icons-material';
import { TextAction } from '$app/interfaces/document';

function BgColorPicker() {
  const { t } = useTranslation();

  const getColorIcon = useCallback((color: string) => {
    return (
      <div
        style={{
          backgroundColor: color,
        }}
        className={'rounded border border-line-divider p-0.5'}
      >
        <FormatColorText />
      </div>
    );
  }, []);
  const colors = useMemo(
    () => [
      {
        name: t('colors.default'),
        key: 'default',
        color: 'transparent',
      },
      {
        name: t('colors.custom'),
        key: 'custom',
        color: 'transparent',
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

  return (
    <ColorPicker
      getColorIcon={getColorIcon}
      icon={
        <FormatColorFill
          sx={{
            width: 18,
            height: 18,
          }}
        />
      }
      colors={colors}
      format={TextAction.Highlight}
      label={t('toolbar.highlight')}
    />
  );
}

export default BgColorPicker;
